// APIService.swift
import Foundation

@MainActor
public class APIService {
    private let baseURL = "https://admin.kinestex.com/api/v1/"
    private let apiKey: String?
    private let companyName: String

    public init(apiKey: String?, companyName: String) {
        self.apiKey = apiKey
        self.companyName = companyName
    }

    // The content API has no session-auth path — a key-less kit must fail fast with
    // a clear message instead of a bare 401.
    private var missingKeyError: String? {
        apiKey == nil
            ? "⚠️ The content API requires an apiKey; session-based auth does not cover it."
            : nil
    }
    
    /// Fetches content data from the API based on the provided parameters.
    ///
    /// - Parameters:
    ///   - category: Optional category filter. `nil` or blank means no filter — all
    ///     categories are returned.
    ///   - includeKinestex: When set, controls whether KinesteX-owned content is
    ///     included in the response by sending `include_kinestex=true|false`.
    ///     When `nil`, the parameter is omitted and the server default applies.
    ///   - customParams: Arbitrary additional query parameters appended to the
    ///     request, allowing a company to apply its own custom filtering on top of
    ///     the standard parameters. Keys and values are validated for disallowed
    ///     characters.
    public func fetchContent(
        contentType: ContentType,
        id: String? = nil,
        title: String? = nil,
        lang: String = "en",
        category: String? = nil,
        bodyParts: [BodyPart]? = nil,
        lastDocId: String? = nil,
        limit: Int? = nil,
        includeKinestex: Bool? = nil,
        customParams: [String: String]? = nil
    ) async -> APIContentResult {
        if let missingKeyError = missingKeyError {
            return .error(missingKeyError)
        }
        // Determine endpoint
        let endpoint: String = {
            switch contentType {
            case .workout:   return "workouts"
            case .plan:      return "plans"
            case .exercise:  return "exercises"
            }
        }()
        
        // Build URL components
        let pathComponent: String
        if let id = id {
            pathComponent = "/\(id)"
        } else if let title = title {
            pathComponent = "/\(title)"
        } else {
            pathComponent = ""
        }
        
        guard var components = URLComponents(
            string: baseURL + endpoint + pathComponent
        ) else {
            return .error("Failed to construct URL.")
        }
        
        // Query items
        var queryItems: [URLQueryItem] = [
            .init(name: "lang", value: lang)
        ]
        // A blank category means "no filter" — never send it to the API, where a
        // whitespace-only value would match nothing.
        if let category = category,
           !category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            queryItems.append(.init(name: "category", value: category))
        }
        if let lastDocId = lastDocId {
            queryItems.append(.init(name: "lastDocId", value: lastDocId))
        }
        if let limit = limit {
            queryItems.append(.init(name: "limit", value: String(limit)))
        }
        if let bodyParts = bodyParts {
            let joined = bodyParts.map(\.rawValue).joined(separator: ",")
            queryItems.append(.init(name: "body_parts", value: joined))
        }
        if let includeKinestex = includeKinestex {
            queryItems.append(.init(name: "include_kinestex", value: includeKinestex ? "true" : "false"))
        }
        if let customParams = customParams {
            for (key, value) in customParams {
                if containsDisallowedCharacters(key) || containsDisallowedCharacters(value) {
                    return .error("Custom parameter '\(key)' contains disallowed characters.")
                }
                queryItems.append(.init(name: key, value: value))
            }
        }
        components.queryItems = queryItems
        
        guard let url = components.url else {
            return .error("Failed to create URL with query parameters.")
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let apiKey = apiKey {
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        }
        request.setValue(companyName, forHTTPHeaderField: "x-company-name")
        print ("KinesteX: Request: \(url)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                print("⚠️ KinesteX: Non-HTTP response")
                return .error("Invalid response from server")
            }
            
            let rawData = data.toJSONDictionary()

            if (200...299).contains(httpResponse.statusCode) {
                return try await parseResponse(
                    data: data,
                    contentType: contentType,
                    isList: id == nil && title == nil,
                    rawData: rawData
                )
            } else {
                // Attempt structured error
                if let errResp = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                    let msg = errResp.message ?? errResp.error ?? "Unknown error"
                    return .error("Error: \(msg)")
                } else {
                    return .error("HTTP \(httpResponse.statusCode)")
                }
            }
        } catch {
            print("⚠️ KinesteX: Network error: \(error)")
            return .error("Network error: \(error.localizedDescription)")
        }
    }
    
    private enum TempCodingKey: String, CodingKey {
        case sequence
    }

    private func parseResponse(
        data: Data,
        contentType: ContentType,
        isList: Bool,
        rawData: [String: Any]?
    ) async throws -> APIContentResult {
        let decoder = JSONDecoder()
        let jsonData = data.toJSONDictionary()
        
        do {
            switch contentType {
            case .workout:
                if isList {
                    // Handle list of workouts
                    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let rawWorkouts = json["workouts"] as? [[String: Any]] else {
                        throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Invalid workouts list"))
                    }
                    let workouts = try rawWorkouts.map { rawWorkout in
                        guard let sequence = rawWorkout["sequence"] as? [[String: Any]] else {
                            throw DecodingError.keyNotFound(TempCodingKey.sequence, .init(codingPath: [], debugDescription: "Sequence not found"))
                        }
                        let processedSequence = processSequence(sequence)
                        var workoutDict = rawWorkout
                        workoutDict["sequence"] = processedSequence
                        let workoutData = try JSONSerialization.data(withJSONObject: workoutDict)
                        return try decoder.decode(WorkoutModel.self, from: workoutData)
                    }
                    
                    let lastDocId = json["lastDocId"] as? String
                    var response = WorkoutsResponse(workouts: workouts, lastDocId: lastDocId)
                    response.captureRawJSON(jsonData)
                    return .workouts(response)
                } else {
                    // Handle single workout
                    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Invalid workout data"))
                    }
                    
                    guard let sequence = json["sequence"] as? [[String: Any]] else {
                        throw DecodingError.keyNotFound(TempCodingKey.sequence, .init(codingPath: [], debugDescription: "Sequence not found"))
                    }
                    
                    let processedSequence = processSequence(sequence)
                    var workoutDict = json
                    workoutDict["sequence"] = processedSequence
                    let workoutData = try JSONSerialization.data(withJSONObject: workoutDict)
                    var workout = try decoder.decode(WorkoutModel.self, from: workoutData)
                    workout.captureRawJSON(jsonData)
                    return .workout(workout)
                }
                
            case .plan:
                if isList {
                    var resp = try decoder.decode(PlansResponse.self, from: data)
                    resp.captureRawJSON(jsonData)
                    return .plans(resp)
                } else {
                    var plan = try decoder.decode(PlanModel.self, from: data)
                    plan.captureRawJSON(jsonData)
                    return .plan(plan)
                }
                
            case .exercise:
                if isList {
                    var resp = try decoder.decode(ExercisesResponse.self, from: data)
                    resp.captureRawJSON(jsonData)
                    return .exercises(resp)
                } else {
                    var exercise = try decoder.decode(ExerciseModel.self, from: data)
                    exercise.captureRawJSON(jsonData)
                    return .exercise(exercise)
                }
            }
        } catch {
            let msg = "Failed to parse \(contentType.rawValue): \(error)"
            print("⚠️ KinesteX: \(msg)")
            if let raw = jsonData {
                print("⚠️ KinesteX: raw JSON:", raw)
                return .rawData(raw, msg)
            }
            return .error(msg)
        }
    }
    
    private func processSequence(_ rawSequence: [[String: Any]]) -> [[String: Any]] {
        var processedExercises: [[String: Any]] = []
        // Stores the countdown from the most recent "Rest" item.
        // Initializes to 0, so an exercise at the beginning of a sequence
        // or one not preceded by a "Rest" item gets 0 rest_duration.
        var currentRestDurationForNextExercise: Int = 0

        for item in rawSequence {
            // Check if the current item is a "Rest" item by its title.
            if item["id"] as? String == "Rest" {
                // If it's a Rest item, update the duration that the *next*
                // exercise should use.
                // Defaults to 10 if "countdown" is missing or not an Int,
                // matching the logic in your KinesteXAIFramework.
                currentRestDurationForNextExercise = item["countdown"] as? Int ?? 10
            } else {
                // If it's an exercise item:
                var exerciseItem = item
                // Assign the stored rest duration (from a preceding Rest item, or 0).
                exerciseItem["rest_duration"] = currentRestDurationForNextExercise
                processedExercises.append(exerciseItem)
                
                // After an exercise is processed, reset the rest duration.
                // This ensures that if two exercises appear consecutively without
                // a "Rest" item between them, the second exercise correctly gets
                // a rest_duration of 0.
                currentRestDurationForNextExercise = 0
            }
        }
        return processedExercises
    }
    
    private func processSteps(_ steps: [String?]?) -> [String] {
        guard let steps = steps else { return [] }
        return steps.compactMap { $0 }.filter { !$0.isEmpty }
    }
    
    private func containsDisallowedCharacters(_ input: String) -> Bool {
        let pattern = "<script>|</script>|[<>{}()\\[\\];\"'\\$\\.#]"
        let regex = try! NSRegularExpression(pattern: pattern)
        let matches = regex.matches(
            in: input,
            range: NSRange(location: 0, length: input.utf16.count)
        )
        return !matches.isEmpty
    }
}

// MARK: - Sendable Conformance for crossing actors
extension APIContentResult: @unchecked Sendable {}
