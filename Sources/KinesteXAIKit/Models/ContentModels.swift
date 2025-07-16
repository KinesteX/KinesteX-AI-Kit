import Foundation

// MARK: - Base Models

/// WorkoutModel represents the structure of a workout returned by the API.
public struct WorkoutModel: Codable, Identifiable, RawDataCapturing {
    public let id: String
    public let title: String
    public let imgURL: String
    public let category: String?
    public let description: String
    public let totalMinutes: Int?
    public let totalCalories: Int?
    public let bodyParts: [String]
    public let difficultyLevel: String?
    public let sequence: [ExerciseModel]
    
    // Raw data storage (not included in Codable)
    private var _rawJSON: [String: Any]?
    
    /// Access to raw JSON data that was used to create this model
    public var rawJSON: [String: Any]? {
        return _rawJSON
    }
    
    /// Sets the raw JSON data for this model
    public mutating func captureRawJSON(_ json: [String: Any]?) {
        self._rawJSON = json
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, category, sequence
        case imgURL = "workout_desc_img"
        case totalMinutes = "total_minutes"
        case totalCalories = "calories"
        case bodyParts = "body_parts"
        case difficultyLevel = "dif_level"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(String.self, forKey: .id)) ?? "NA"
        title = (try? container.decode(String.self, forKey: .title)) ?? "Untitled Workout"
        imgURL = (try? container.decode(String.self, forKey: .imgURL)) ?? ""
        category = try? container.decodeIfPresent(String.self, forKey: .category)
        description = (try? container.decode(String.self, forKey: .description)) ?? ""
        totalMinutes = try? container.decodeIfPresent(Int.self, forKey: .totalMinutes)
        totalCalories = try? container.decodeIfPresent(Int.self, forKey: .totalCalories)
        bodyParts = (try? container.decode([String].self, forKey: .bodyParts)) ?? []
        difficultyLevel = try? container.decodeIfPresent(String.self, forKey: .difficultyLevel)
        sequence = (try? container.decode([ExerciseModel].self, forKey: .sequence)) ?? []
    }
}

/// ExerciseModel represents the details of an exercise included in a workout or independently.
public struct ExerciseModel: Codable, Identifiable, RawDataCapturing {
    public let id: String
    public let title: String
    public let thumbnailURL: String
    public let videoURL: String
    public let maleVideoURL: String
    public let maleThumbnailURL: String
    public let workoutCountdown: Int?
    public let workoutReps: Int?
    public let averageReps: Int?
    public let averageCountdown: Int?
    public let restDuration: Int?
    public let restSpeech: String
    public let restSpeechText: String
    public let averageCalories: Double?
    public let bodyParts: [String]
    public let description: String
    public let difficultyLevel: String
    public let commonMistakes: String
    public let steps: [String]
    public let tips: String
    public let modelId: String
    
    // Raw data storage (not included in Codable)
    private var _rawJSON: [String: Any]?
    
    /// Access to raw JSON data that was used to create this model
    public var rawJSON: [String: Any]? {
        return _rawJSON
    }
    
    /// Sets the raw JSON data for this model
    public mutating func captureRawJSON(_ json: [String: Any]?) {
        self._rawJSON = json
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, steps, tips
        case thumbnailURL = "thumbnail_URL"
        case videoURL = "video_URL"
        case workoutCountdown = "workout_countdown"
        case workoutReps = "workout_repeats"
        case averageReps = "avg_reps"
        case averageCountdown = "avg_countdown"
        case restDuration = "rest_duration"
        case restSpeech = "rest_speech"
        case restSpeechText = "rest_speech_text"
        case averageCalories = "avg_cal"
        case bodyParts = "body_parts"
        case difficultyLevel = "dif_level"
        case commonMistakes = "common_mistakes"
        case modelId = "model_id"
        case maleVideoURL = "male_video_URL"
        case maleThumbnailURL = "male_thumbnail_URL"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = (try? container.decode(String.self, forKey: .id)) ?? "NA"
        title = (try? container.decode(String.self, forKey: .title)) ?? "Untitled Exercise"
        thumbnailURL = (try? container.decode(String.self, forKey: .thumbnailURL)) ?? ""
        videoURL = (try? container.decode(String.self, forKey: .videoURL)) ?? ""
        maleVideoURL = (try? container.decode(String.self, forKey: .maleVideoURL)) ?? ""
        maleThumbnailURL = (try? container.decode(String.self, forKey: .maleThumbnailURL)) ?? ""
        workoutCountdown = try? container.decodeIfPresent(Int.self, forKey: .workoutCountdown)
        workoutReps = try? container.decodeIfPresent(Int.self, forKey: .workoutReps)
        averageReps = try? container.decodeIfPresent(Int.self, forKey: .averageReps)
        averageCountdown = try? container.decodeIfPresent(Int.self, forKey: .averageCountdown)
        restDuration = (try? container.decodeIfPresent(Int.self, forKey: .restDuration)) ?? 10
        restSpeech = (try? container.decode(String.self, forKey: .restSpeech)) ?? ""
        restSpeechText = (try? container.decode(String.self, forKey: .restSpeechText)) ?? ""
        averageCalories = try? container.decodeIfPresent(Double.self, forKey: .averageCalories)
        bodyParts = (try? container.decode([String].self, forKey: .bodyParts)) ?? []
        description = (try? container.decode(String.self, forKey: .description)) ?? "Missing exercise description"
        difficultyLevel = (try? container.decode(String.self, forKey: .difficultyLevel)) ?? "Medium"
        commonMistakes = (try? container.decode(String.self, forKey: .commonMistakes)) ?? ""
        steps = (try? container.decode([String].self, forKey: .steps)) ?? []
        tips = (try? container.decode(String.self, forKey: .tips)) ?? ""
        modelId = (try? container.decode(String.self, forKey: .modelId)) ?? "NA"
    }
}

/// PlanModel represents a workout plan containing structured workouts at various levels.
public struct PlanModel: Codable, Identifiable, RawDataCapturing {
    public let id: String
    public let imgURL: String
    public let title: String
    public let category: PlanModelCategory
    public let levels: [String: PlanLevel]
    public let createdBy: String
    
    // Raw data storage (not included in Codable)
    private var _rawJSON: [String: Any]?
    
    /// Access to raw JSON data that was used to create this model
    public var rawJSON: [String: Any]? {
        return _rawJSON
    }
    
    /// Sets the raw JSON data for this model
    public mutating func captureRawJSON(_ json: [String: Any]?) {
        self._rawJSON = json
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, levels
        case imgURL = "img_URL"
        case category
        case createdBy = "created_by"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        imgURL = try container.decode(String.self, forKey: .imgURL)
        title = try container.decode(String.self, forKey: .title)
        category = try container.decode(PlanModelCategory.self, forKey: .category)
        levels = try container.decode([String: PlanLevel].self, forKey: .levels)
        createdBy = try container.decode(String.self, forKey: .createdBy)
    }
}

/// PlanModelCategory defines a category within a workout plan.
public struct PlanModelCategory: Codable, RawDataCapturing {
    public let description: String
    public let levels: [String: Int] // e.g., "Cardio": 2, "Strength": 3
    
    // Raw data storage (not included in Codable)
    private var _rawJSON: [String: Any]?
    
    /// Access to raw JSON data that was used to create this model
    public var rawJSON: [String: Any]? {
        return _rawJSON
    }
    
    /// Sets the raw JSON data for this model
    public mutating func captureRawJSON(_ json: [String: Any]?) {
        self._rawJSON = json
    }
    
    enum CodingKeys: String, CodingKey {
        case description, levels
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        description = try container.decode(String.self, forKey: .description)
        levels = try container.decode([String: Int].self, forKey: .levels)
    }
}

/// PlanLevel defines a specific level within a workout plan.
public struct PlanLevel: Codable, RawDataCapturing {
    public let title: String
    public let description: String
    public let days: [String: PlanDay]
    
    // Raw data storage (not included in Codable)
    private var _rawJSON: [String: Any]?
    
    /// Access to raw JSON data that was used to create this model
    public var rawJSON: [String: Any]? {
        return _rawJSON
    }
    
    /// Sets the raw JSON data for this model
    public mutating func captureRawJSON(_ json: [String: Any]?) {
        self._rawJSON = json
    }
    
    enum CodingKeys: String, CodingKey {
        case title, description, days
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        days = try container.decode([String: PlanDay].self, forKey: .days)
    }
}

/// PlanDay represents a day within a plan level.
public struct PlanDay: Codable, RawDataCapturing {
    public let title: String
    public let description: String
    public let workouts: [WorkoutSummary]?
    
    // Raw data storage (not included in Codable)
    private var _rawJSON: [String: Any]?
    
    /// Access to raw JSON data that was used to create this model
    public var rawJSON: [String: Any]? {
        return _rawJSON
    }
    
    /// Sets the raw JSON data for this model
    public mutating func captureRawJSON(_ json: [String: Any]?) {
        self._rawJSON = json
    }
    
    enum CodingKeys: String, CodingKey {
        case title, description, workouts
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        workouts = try container.decodeIfPresent([WorkoutSummary].self, forKey: .workouts)
    }
}

/// WorkoutSummary provides basic information about a workout within a plan day.
public struct WorkoutSummary: Codable, Identifiable, RawDataCapturing {
    public let id: String
    public let imgURL: String
    public let title: String
    public let calories: Double?
    public let totalMinutes: Int
    
    // Raw data storage (not included in Codable)
    private var _rawJSON: [String: Any]?
    
    /// Access to raw JSON data that was used to create this model
    public var rawJSON: [String: Any]? {
        return _rawJSON
    }
    
    /// Sets the raw JSON data for this model
    public mutating func captureRawJSON(_ json: [String: Any]?) {
        self._rawJSON = json
    }
    
    enum CodingKeys: String, CodingKey {
        case id, imgURL, title, calories
        case totalMinutes = "total_minutes"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        imgURL = try container.decode(String.self, forKey: .imgURL)
        title = try container.decode(String.self, forKey: .title)
        calories = try container.decodeIfPresent(Double.self, forKey: .calories)
        totalMinutes = try container.decode(Int.self, forKey: .totalMinutes)
    }
}

// MARK: - API Response Models

public struct WorkoutsResponse: Codable, RawDataCapturing {
    public let workouts: [WorkoutModel]
    public let lastDocId: String
    
    // Raw data storage (not included in Codable)
    private var _rawJSON: [String: Any]?
    
    /// Access to raw JSON data that was used to create this model
    public var rawJSON: [String: Any]? {
        return _rawJSON
    }
    
    /// Sets the raw JSON data for this model
    public mutating func captureRawJSON(_ json: [String: Any]?) {
        self._rawJSON = json
    }
    
    enum CodingKeys: String, CodingKey {
        case workouts, lastDocId
    }
    
    // Codable initializer for decoding JSON
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        workouts = try container.decode([WorkoutModel].self, forKey: .workouts)
        lastDocId = try container.decode(String.self, forKey: .lastDocId)
    }
    
    // Custom initializer for direct initialization
    public init(workouts: [WorkoutModel], lastDocId: String) {
        self.workouts = workouts
        self.lastDocId = lastDocId
    }
}

public struct ExercisesResponse: Codable, RawDataCapturing {
    public let exercises: [ExerciseModel]
    public let lastDocId: String
    
    // Raw data storage (not included in Codable)
    private var _rawJSON: [String: Any]?
    
    /// Access to raw JSON data that was used to create this model
    public var rawJSON: [String: Any]? {
        return _rawJSON
    }
    
    /// Sets the raw JSON data for this model
    public mutating func captureRawJSON(_ json: [String: Any]?) {
        self._rawJSON = json
    }
    
    enum CodingKeys: String, CodingKey {
        case exercises, lastDocId
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        exercises = try container.decode([ExerciseModel].self, forKey: .exercises)
        lastDocId = try container.decode(String.self, forKey: .lastDocId)
    }
}

public struct PlansResponse: Codable, RawDataCapturing {
    public let plans: [PlanModel]
    public let lastDocId: String
    
    // Raw data storage (not included in Codable)
    private var _rawJSON: [String: Any]?
    
    /// Access to raw JSON data that was used to create this model
    public var rawJSON: [String: Any]? {
        return _rawJSON
    }
    
    /// Sets the raw JSON data for this model
    public mutating func captureRawJSON(_ json: [String: Any]?) {
        self._rawJSON = json
    }
    
    enum CodingKeys: String, CodingKey {
        case plans, lastDocId
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        plans = try container.decode([PlanModel].self, forKey: .plans)
        lastDocId = try container.decode(String.self, forKey: .lastDocId)
    }
}

struct APIErrorResponse: Codable {
    let message: String?
    let error: String?
}

// MARK: - JSON Conversion Extensions
extension Data {
    /// Converts Data to a JSON dictionary if possible
    func toJSONDictionary() -> [String: Any]? {
        return try? JSONSerialization.jsonObject(with: self) as? [String: Any]
    }
}
