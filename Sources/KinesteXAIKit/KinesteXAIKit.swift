import SwiftUI
import AVKit

@MainActor
@available(iOS 13, macOS 10.15, *)
public struct KinesteXAIKit {
    public var baseURL = URL(string: "https://kinestex.vercel.app")!
    public var apiKey: String
    public var companyName: String
    public var userId: String
    
    // MARK: - WebView State Management
    private static var globalWebViewState: WebViewState?
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
    /// Launches personalized plan view (beta preview).  Please contact KinesteX for access
    ///
    /// - Parameters:
    ///   - user: Optional user details like height, age, weight, lifestyle, gender
    ///   - isLoading: Variable flag to inform you of the loading state changes
    ///   - customParams: Custom params for advanced configuration
    ///   - onMessageReceived: Callback function to react to events in KinesteX
    ///
    /// - Returns: A webview page with personalized plan that remembers user's state based on userId
    /// Launches personalized plan view (beta preview).  Please contact KinesteX for access
    public func createPersonalizedPlanView(
        user: UserDetails?,
        isLoading: Binding<Bool>,
        customParams: [String: Any] = [:],
        onMessageReceived: @escaping (KinestexMessage) -> Void
    ) -> AnyView {
        return makeView(
            endpoint: "personalized-plan",
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
    
    public func createCustomWorkoutView(
        exercises: [WorkoutSequenceExercise],
        user: UserDetails?,
        isLoading: Binding<Bool>,
        customParams: [String: Any] = [:],
        onMessageReceived: @escaping (KinestexMessage) -> Void
    ) -> AnyView {
        let normalized = normalizeWorkoutExercises(exercises)
        
        print(normalized)
        
        let defaultData: [String: Any] = [
            "customWorkoutExercises": normalized as Any
        ]
        
        return makeView(
            endpoint: "custom-workout",
            defaultData: defaultData,
            user: user,
            customParams: customParams,
            isLoading: isLoading,
            onMessageReceived: onMessageReceived
        )
    }
    
    /// Builds the Admin Workout Editor view.
    public func createAdminWorkoutEditor(
        organization: String,
        contentType: AdminContentType? = nil,
        contentId: String? = nil,
        customQueries: [String: String]? = nil,
        isLoading: Binding<Bool>,
        customParams: [String: Any] = [:],
        onMessageReceived: @escaping (KinestexMessage) -> Void
    ) -> AnyView {
        // 1 Base admin URL
        var url = URL(string: "https://admin.kinestex.com")!
        
        if let type = contentType, let id = contentId {
            url.appendPathComponent(type.segment)
            url.appendPathComponent(id)
        } else {
            url.appendPathComponent("main")
        }

        // 3 Add query parameters
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        var queryItems = [
            URLQueryItem(name: "isCustomAuth", value: "true"),
            URLQueryItem(name: "hideSidebar", value: "true")
        ]
        
        if let queries = customQueries {
            for (k, v) in queries {
                queryItems.append(URLQueryItem (name: k, value: v))
            }
        }

        components.queryItems = queryItems
        let fullURLString = components.url!.absoluteString
        
        // 4 Default payload
        let defaultData: [String: Any] = [
            "organization": organization,
            "apiKey": apiKey,
            "companyName": companyName
        ]
        
        // 5 Call makeView with the full URL as endpoint
        return makeView(
            endpoint: fullURLString,
            defaultData: defaultData,
            user: nil,
            customParams: customParams,
            isLoading: isLoading,
            onMessageReceived: onMessageReceived,
            useCustomURL: true
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
    
    // MARK: - Send Action Methods
    
    /// Sets the global WebView state for static sendAction method
    public static func setGlobalWebViewState(_ state: WebViewState) {
        globalWebViewState = state
        print("🔄 KinesteX: Global WebView state updated, webView is \(state.webView != nil ? "ready" : "not ready")")
    }
    
    /// Check if the WebView is ready to receive actions
    /// - Returns: True if actions can be sent, false otherwise
    public static func isWebViewReady() -> Bool {
        return globalWebViewState?.webView != nil
    }
    
    /// Wait for WebView to be ready with a timeout
    /// - Parameters:
    ///   - timeout: Maximum time to wait in seconds (default: 5.0)
    ///   - completion: Called when WebView is ready or timeout occurs
    public static func waitForWebViewReady(timeout: TimeInterval = 5.0, completion: @escaping (Bool) -> Void) {
        let startTime = Date()
        
        func checkReadiness() {
            if isWebViewReady() {
                completion(true)
                return
            }
            
            if Date().timeIntervalSince(startTime) > timeout {
                print("⏰ KinesteX: WebView ready timeout after \(timeout) seconds")
                completion(false)
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                checkReadiness()
            }
        }
        
        checkReadiness()
    }
    
    /// Static method to send actions through the global WebView
    /// - Parameters:
    ///   - action: The action key (e.g., "workout_activity_action")
    ///   - value: The action value (e.g., "start", "pause", "stop")
    public static func sendAction(_ action: String, value: String) {
        // Enhanced debugging to understand the state
        if globalWebViewState == nil {
            print("⚠️ KinesteX: Cannot send action - Global WebView state is nil")
            print("💡 KinesteX: Make sure a KinesteX view is currently displayed")
            return
        }
        
        guard let webView = globalWebViewState?.webView else {
            print("⚠️ KinesteX: Cannot send action - WebView not ready or not set")
            print("💡 KinesteX: WebView state exists but webView is nil - likely still loading")
            return
        }
        
        guard !action.isEmpty else {
            print("⚠️ KinesteX: Action type is required")
            return
        }
        
        guard !value.isEmpty else {
            print("⚠️ KinesteX: Action value is required")
            return
        }
        
        let script = """
        (function() {
            const message = { '\(action)': '\(value)' };
            window.postMessage(message, '*');
        })();
        """
        
        print("📤 KinesteX: Sending action: \(action) = \(value)")
        
        webView.evaluateJavaScript(script) { _, error in
            if let error = error {
                print("⚠️ KinesteX: Failed to send action - \(error.localizedDescription)")
            } else {
                print("✅ KinesteX: Action sent successfully")
            }
        }
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
        currentRestSpeech: Binding<String?>? = nil,
        useCustomURL: Bool = false
    ) -> AnyView {
        guard let payload = preparePayload(
            defaultData: defaultData,
            user: user,
            customParams: customParams
        ) else {
            return AnyView(EmptyView())
        }
        
        let url: URL
        if useCustomURL {
            // When useCustomURL is true, treat endpoint as a full URL string
            url = URL(string: endpoint) ?? baseURL
        } else {
            // Default behavior: append endpoint to baseURL
            url = baseURL.appendingPathComponent(endpoint)
        }
        
        let kinestexView = KinestexView(
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
        
        return AnyView(kinestexView)
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
