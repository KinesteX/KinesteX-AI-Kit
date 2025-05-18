import SwiftUI

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
    }
    
    // MARK: - Public API
    @MainActor
    @available(iOS 13, macOS 10.15, *)
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
            "currentExercise": currentExercise.wrappedValue ?? ""
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
    
    @MainActor
    @available(iOS 13, macOS 10.15, *)
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
    
    @MainActor
    @available(iOS 13, macOS 10.15, *)
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
    @MainActor
    @available(iOS 13, macOS 10.15, *)
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
    
    @MainActor
    @available(iOS 13, macOS 10.15, *)
    public func createExperienceView(
        experience: String,
        duration: Int = 60,
        user: UserDetails?,
        isLoading: Binding<Bool>,
        customParams: [String: Any] = [:],
        onMessageReceived: @escaping (KinestexMessage) -> Void
    ) -> AnyView {
        let defaultData: [String: Any] = [
            "countdown": duration,
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
    
    @MainActor
    @available(iOS 13, macOS 10.15, *)
    public func createLeaderboardView(
        exercise: String,
        username: String = "",
        user: UserDetails?,
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
            user: user,
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
}
