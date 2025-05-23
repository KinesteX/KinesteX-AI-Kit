import SwiftUI
import AVKit

@MainActor
@available(iOS 13, macOS 10.15, *)
public struct KinesteXAIKit {
    public var baseURL = URL(string: "https://kinestex.vercel.app")!
    public var apiKey: String
    public var companyName: String
    public var userId: String
    public init(
        baseURL: URL? = nil,
        apiKey: String,
        companyName: String,
        userId: String
    ) {
        if let u = baseURL { self.baseURL = u }
        self.apiKey = apiKey
        self.companyName = companyName
        self.userId = userId
        // eagerly initialize your service
        self.apiService = APIService(apiKey: apiKey, companyName: companyName)
    }
    private let apiService: APIService
    /// Fetches content data from the KinesteX API.
    ///
    /// - Parameters:
    ///   - contentType: The type of content to fetch (.workout, .plan, or .exercise).
    ///   - id: An optional unique identifier for the content.
    ///   - title: An optional title used to search for the content.
    ///   - lang: The language for the content; defaults to English ("en").
    ///   - category: An optional category to filter workouts and plans.
    ///   - bodyParts: An optional array of `BodyPart` to filter content.
    ///   - lastDocId: An optional document ID for pagination.
    ///   - limit: An optional limit on the number of items to fetch.
    ///
    /// - Returns: A task that provides an `APIContentResult` containing the requested content or an error.
    /// Fetches content data from the KinesteX API.
    public func fetchContent(
        contentType: ContentType,
        id: String? = nil,
        title: String? = nil,
        lang: String = "en",
        category: String? = nil,
        bodyParts: [BodyPart]? = nil,
        lastDocId: String? = nil,
        limit: Int? = nil
    ) async -> APIContentResult {
        // now simply calls your service; no mutation required
        return await apiService.fetchContent(
            contentType: contentType,
            id: id,
            title: title,
            lang: lang,
            category: category,
            bodyParts: bodyParts,
            lastDocId: lastDocId,
            limit: limit
        )
    }
    
    // MARK: - Public API
    
    public func createCameraView(
        exercises: [String],
        currentExercise: Binding<String>,
        currentRestSpeech: Binding<String?>? = nil,
        user: UserDetails?,
        isLoading: Binding<Bool>,
        customParams: [String: Any] = [:],
        onMessageReceived: @escaping (KinestexMessage) -> Void
    ) -> AnyView {
        let defaultData: [String: Any] = [
            "exercises": exercises,
            "currentExercise": currentExercise.wrappedValue
        ]
        let nullableCurrentExercise = Binding<String?>(
            get: { currentExercise.wrappedValue },
            set: { newValue in
                guard let v = newValue else { return }
                currentExercise.wrappedValue = v
            }
        )
        return makeView(
            endpoint: "camera",
            defaultData: defaultData,
            user: user,
            customParams: customParams,
            isLoading: isLoading,
            onMessageReceived: onMessageReceived,
            currentExercise: nullableCurrentExercise,
            currentRestSpeech: currentRestSpeech
        )
    }
    
    
    public func createPlanView(
        plan: String,
        user: UserDetails?,
        isLoading: Binding<Bool>,
        customParams: [String: Any] = [:],
        onMessageReceived: @escaping (KinestexMessage) -> Void
    ) -> AnyView {
        let safePlan = plan.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? plan
        return makeView(
            endpoint: "plan/\(safePlan)",
            defaultData: [:],
            user: user,
            customParams: customParams,
            isLoading: isLoading,
            onMessageReceived: onMessageReceived
        )
    }
    
    public func createCategoryView(
        planCategory: PlanCategory = .Cardio,
        user: UserDetails?,
        isLoading: Binding<Bool>,
        customParams: [String: Any] = [:],
        onMessageReceived: @escaping (KinestexMessage) -> Void
    ) -> AnyView {
        let categoryString = planCategoryString(planCategory)
        if containsDisallowedCharacters(categoryString) {
            print("⚠️ KinesteX: Validation error, plan cateogory contains disallowed characters")
            return AnyView(EmptyView())
        }
        let defaultData = [
            "planC": categoryString
        ]
        
        return makeView(endpoint: "",
                    defaultData: defaultData,
                    user: user,
                    customParams: customParams,
                    isLoading: isLoading,
                    onMessageReceived: onMessageReceived)
    }
    
    public func createHowToView(
        videoURL: String? = nil,  // Optional URL, default to the predefined URL
        onVideoEnd: @escaping () -> Void
    ) -> AnyView {
        let defaultVideoURL = "https://cdn.kinestex.com/SDK%2Fhow-to-video%2Foutput_compressed.mp4?alt=media&token=9a3c0ed8-c86b-4553-86dd-a96f23e55f74"
        
        let url = URL(string: videoURL ?? defaultVideoURL)!
        let player = AVPlayer(url: url)
        
        // Store the observer so we can remove it later
        var observer: NSObjectProtocol?
        
        let playerView = VideoPlayer(player: player)
            .onAppear {
                player.play()
                
                // Add observer for video end
                observer = NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: player.currentItem,
                    queue: .main
                ) { _ in
                    onVideoEnd()
                }
            }
            .onDisappear {
                player.pause()
                
                // Remove observer safely when the view disappears
                if let observer = observer {
                    NotificationCenter.default.removeObserver(observer)
                }
            }
        
        return AnyView(playerView)
    }
    
    public func createWorkoutView(
        workout: String,
        user: UserDetails?,
        isLoading: Binding<Bool>,
        customParams: [String: Any] = [:],
        onMessageReceived: @escaping (KinestexMessage) -> Void
    ) -> AnyView {
        let safeWorkout = workout.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? workout
        return makeView(
            endpoint: "workout/\(safeWorkout)",
            defaultData: [:],
            user: user,
            customParams: customParams,
            isLoading: isLoading,
            onMessageReceived: onMessageReceived
        )
    }
    
    public func createChallengeView(
        exercise: String,
        duration: Int,
        showLeaderboard: Bool = true,
        user: UserDetails?,
        isLoading: Binding<Bool>,
        customParams: [String: Any] = [:],
        onMessageReceived: @escaping (KinestexMessage) -> Void
    ) -> AnyView {
        let defaultData: [String: Any] = [
            "exercise": exercise,
            "countdown": duration,
            "showLeaderboard": showLeaderboard
        ]
        return makeView(
            endpoint: "challenge",
            defaultData: defaultData,
            user: user,
            customParams: customParams,
            isLoading: isLoading,
            onMessageReceived: onMessageReceived,
        )
    }
    
    
    public func createExperienceView(
        experience: String,
        exercise: String,
        duration: Int = 60,
        user: UserDetails?,
        isLoading: Binding<Bool>,
        customParams: [String: Any] = [:],
        onMessageReceived: @escaping (KinestexMessage) -> Void
    ) -> AnyView {
        let defaultData: [String: Any] = [
            "countdown": duration,
            "exercise": exercise
        ]
        let safeExperience = experience.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? experience
        return makeView(
            endpoint: "experiences/\(safeExperience)",
            defaultData: defaultData,
            user: user,
            customParams: customParams,
            isLoading: isLoading,
            onMessageReceived: onMessageReceived,
        )
    }
    
    public func createLeaderboardView(
        exercise: String,
        username: String = "",
        isLoading: Binding<Bool>,
        customParams: [String: Any] = [:],
        onMessageReceived: @escaping (KinestexMessage) -> Void
    ) -> AnyView {
        let defaultData: [String: Any] = [
            "exercise": exercise,
        ]
        let safeUsername = username.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? username
        return makeView(
            endpoint: safeUsername.isEmpty ? "leaderboard" : "leaderboard/?username=\(safeUsername)",
            defaultData: defaultData,
            user: nil,
            customParams: customParams,
            isLoading: isLoading,
            onMessageReceived: onMessageReceived,
        )
    }
    
    
    private func preparePayload(
        defaultData: [String: Any],
        user: UserDetails?,
        customParams: [String: Any]
    ) -> [String: Any]? {
        var merged = defaultData
        
        // attach user details
        if let u = user {
            merged["age"] = u.age
            merged["height"] = u.height
            merged["weight"] = u.weight
            merged["gender"] = genderString(u.gender)
            merged["lifestyle"] = lifestyleString(u.lifestyle)
        }
        
        // attach custom overrides
        merged.merge(customParams) { _, new in new }
        
        // validate once
        guard validateInput(
            apiKey: apiKey,
            companyName: companyName,
            userId: userId,
            customParams: merged
        ) else {
            print("⚠️ KinesteX: Input validation failed.")
            return nil
        }
        
        return merged
    }
    
    /// Builds the KinestexView or returns an EmptyView on failure.
    @MainActor
    private func makeView(
        endpoint: String,
        defaultData: [String: Any],
        user: UserDetails?,
        customParams: [String: Any],
        isLoading: Binding<Bool>,
        onMessageReceived: @escaping (KinestexMessage) -> Void,
        currentExercise: Binding<String?>? = nil,
        currentRestSpeech: Binding<String?>? = nil
    ) -> AnyView {
        guard let payload = preparePayload(
            defaultData: defaultData,
            user: user,
            customParams: customParams
        ) else {
            return AnyView(EmptyView())
        }
        
        let url = baseURL.appendingPathComponent(endpoint)
        return AnyView(
            KinestexView(
                apiKey: apiKey,
                companyName: companyName,
                userId: userId,
                url: url,
                data: payload,
                isLoading: isLoading,
                onMessageReceived: onMessageReceived,
                currentExercise: currentExercise ?? .constant(nil),
                currentRestSpeech: currentRestSpeech ?? .constant(nil)
            )
        )
    }
    
    
    /// Fetches a specific workout by ID.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the workout.
    ///   - lang: The language for the content; defaults to English ("en").
    ///
    /// - Returns: A task that provides a WorkoutModel or an error.
    public func fetchWorkout(id: String, lang: String = "en") async -> Result<WorkoutModel, Error> {
        let result = await fetchContent(contentType: .workout, id: id, lang: lang)
        
        switch result {
        case .workout(let workout):
            return .success(workout)
        case .rawData(let data, let errorMessage):
            return .failure(NSError(
                domain: "KinesteXAIKit",
                code: 422,
                userInfo: [
                    NSLocalizedDescriptionKey: errorMessage ?? "Failed to parse workout data",
                    "rawData": data
                ]
            ))
        case .error(let message):
            return .failure(NSError(
                domain: "KinesteXAIKit",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: message]
            ))
        default:
            return .failure(NSError(
                domain: "KinesteXAIKit",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Unexpected result type"]
            ))
        }
    }
    
    /// Fetches a specific exercise by ID.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the exercise.
    ///   - lang: The language for the content; defaults to English ("en").
    ///
    /// - Returns: A task that provides an ExerciseModel or an error.
    public func fetchExercise(id: String, lang: String = "en") async -> Result<ExerciseModel, Error> {
        let result = await fetchContent(contentType: .exercise, id: id, lang: lang)
        
        switch result {
        case .exercise(let exercise):
            return .success(exercise)
        case .rawData(let data, let errorMessage):
            return .failure(NSError(
                domain: "KinesteXAIKit",
                code: 422,
                userInfo: [
                    NSLocalizedDescriptionKey: errorMessage ?? "Failed to parse exercise data",
                    "rawData": data
                ]
            ))
        case .error(let message):
            return .failure(NSError(
                domain: "KinesteXAIKit",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: message]
            ))
        default:
            return .failure(NSError(
                domain: "KinesteXAIKit",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Unexpected result type"]
            ))
        }
    }
    
    /// Fetches a specific workout plan by ID.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the plan.
    ///   - lang: The language for the content; defaults to English ("en").
    ///
    /// - Returns: A task that provides a PlanModel or an error.
    public func fetchPlan(id: String, lang: String = "en") async -> Result<PlanModel, Error> {
        let result = await fetchContent(contentType: .plan, id: id, lang: lang)
        
        switch result {
        case .plan(let plan):
            return .success(plan)
        case .rawData(let data, let errorMessage):
            return .failure(NSError(
                domain: "KinesteXAIKit",
                code: 422,
                userInfo: [
                    NSLocalizedDescriptionKey: errorMessage ?? "Failed to parse plan data",
                    "rawData": data
                ]
            ))
        case .error(let message):
            return .failure(NSError(
                domain: "KinesteXAIKit",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: message]
            ))
        default:
            return .failure(NSError(
                domain: "KinesteXAIKit",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Unexpected result type"]
            ))
        }
    }
    
    /// Fetches workouts based on filter criteria.
    ///
    /// - Parameters:
    ///   - category: An optional category to filter workouts.
    ///   - bodyParts: An optional array of body parts to filter workouts.
    ///   - limit: Maximum number of workouts to fetch.
    ///   - lastDocId: Optional document ID for pagination.
    ///   - lang: The language for the content; defaults to English ("en").
    ///
    /// - Returns: A task that provides a WorkoutsResponse or an error.
    public func fetchWorkouts(
        category: String? = nil,
        bodyParts: [BodyPart]? = nil,
        limit: Int? = 10,
        lastDocId: String? = nil,
        lang: String = "en"
    ) async -> Result<WorkoutsResponse, Error> {
        let result = await fetchContent(
            contentType: .workout,
            lang: lang,
            category: category,
            bodyParts: bodyParts,
            lastDocId: lastDocId,
            limit: limit
        )
        
        switch result {
        case .workouts(let workouts):
            return .success(workouts)
        case .rawData(let data, let errorMessage):
            return .failure(NSError(
                domain: "KinesteXAIKit",
                code: 422,
                userInfo: [
                    NSLocalizedDescriptionKey: errorMessage ?? "Failed to parse workouts data",
                    "rawData": data
                ]
            ))
        case .error(let message):
            return .failure(NSError(
                domain: "KinesteXAIKit",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: message]
            ))
        default:
            return .failure(NSError(
                domain: "KinesteXAIKit",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Unexpected result type"]
            ))
        }
    }
    
    /// Fetches exercises based on filter criteria.
    ///
    /// - Parameters:
    ///   - bodyParts: An optional array of body parts to filter exercises.
    ///   - limit: Maximum number of exercises to fetch.
    ///   - lastDocId: Optional document ID for pagination.
    ///   - lang: The language for the content; defaults to English ("en").
    ///
    /// - Returns: A task that provides an ExercisesResponse or an error.
    public func fetchExercises(
        bodyParts: [BodyPart]? = nil,
        limit: Int? = 10,
        lastDocId: String? = nil,
        lang: String = "en"
    ) async -> Result<ExercisesResponse, Error> {
        let result = await fetchContent(
            contentType: .exercise,
            lang: lang,
            bodyParts: bodyParts,
            lastDocId: lastDocId,
            limit: limit
        )
        
        switch result {
        case .exercises(let exercises):
            return .success(exercises)
        case .rawData(let data, let errorMessage):
            return .failure(NSError(
                domain: "KinesteXAIKit",
                code: 422,
                userInfo: [
                    NSLocalizedDescriptionKey: errorMessage ?? "Failed to parse exercises data",
                    "rawData": data
                ]
            ))
        case .error(let message):
            return .failure(NSError(
                domain: "KinesteXAIKit",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: message]
            ))
        default:
            return .failure(NSError(
                domain: "KinesteXAIKit",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Unexpected result type"]
            ))
        }
    }
    
    /// Fetches plans based on filter criteria.
    ///
    /// - Parameters:
    ///   - category: An optional category to filter plans.
    ///   - limit: Maximum number of plans to fetch.
    ///   - lastDocId: Optional document ID for pagination.
    ///   - lang: The language for the content; defaults to English ("en").
    ///
    /// - Returns: A task that provides a PlansResponse or an error.
    public func fetchPlans(
        category: String? = nil,
        limit: Int? = 10,
        lastDocId: String? = nil,
        lang: String = "en"
    ) async -> Result<PlansResponse, Error> {
        let result = await fetchContent(
            contentType: .plan,
            lang: lang,
            category: category,
            lastDocId: lastDocId,
            limit: limit
        )
        
        switch result {
        case .plans(let plans):
            return .success(plans)
        case .rawData(let data, let errorMessage):
            return .failure(NSError(
                domain: "KinesteXAIKit",
                code: 422,
                userInfo: [
                    NSLocalizedDescriptionKey: errorMessage ?? "Failed to parse plans data",
                    "rawData": data
                ]
            ))
        case .error(let message):
            return .failure(NSError(
                domain: "KinesteXAIKit",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: message]
            ))
        default:
            return .failure(NSError(
                domain: "KinesteXAIKit",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Unexpected result type"]
            ))
        }
    }
}
