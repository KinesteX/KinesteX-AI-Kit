import SwiftUI

public struct KinesteXAIKit {
    public var baseURL = URL(string: "https://kinestex.vercel.app")!
    public var apiKey: String
    public var companyName: String
    public var userId: String
    public init(baseURL: URL? = nil, apiKey: String, companyName: String, userId: String) {
        if let baseURL = baseURL {
            self.baseURL = baseURL
        }
        self.apiKey = apiKey
        self.companyName = companyName
        self.userId = userId
    }
    @MainActor @available(iOS 13.0, macOS 10.15, *)
    public func createCameraComponent(
        exercises: [String],
        currentExercise: Binding<String>, // Changed to Binding
        currentRestSpeech: Binding<String?>?, // Added for dynamic updates
        user: UserDetails?,
        isLoading: Binding<Bool>,
        customParams: [String: Any] = [:],
        onMessageReceived: @escaping (WebViewMessage) -> Void
    ) -> AnyView {
        var allData = [
            "exercises": exercises,
            "currentExercise": currentExercise.wrappedValue
        ] as [String : Any]
        
        // Validation
        if !validateInput(
            apiKey: apiKey,
            companyName: companyName,
            userId: userId,
            customParams: allData.merging(customParams) { (_, new) in new }
        ) {
            // Specific error messages are printed within validateInput
            print("⚠️ KinesteX: Input validation failed. Component will not be created.")
            return AnyView(EmptyView())
        }
        
        // Construct data dictionary
        var data: [String: Any] = [
            "exercises": exercises,
            "currentExercise": currentExercise.wrappedValue
        ]
        if let user = user {
            data["age"] = user.age
            data["height"] = user.height
            data["weight"] = user.weight
            data["gender"] = genderString(user.gender)
            data["lifestyle"] = lifestyleString(user.lifestyle)
        }
        for (key, value) in customParams {
            data[key] = value
        }
        
        return AnyView(CameraView(
            apiKey: self.apiKey,
            companyName: self.companyName,
            userId: self.userId,
            url: self.baseURL.appendingPathComponent("camera"),
            data: data,
            isLoading: isLoading,
            onMessageReceived: onMessageReceived,
            currentExercise: currentExercise,
            currentRestSpeech: currentRestSpeech ?? Binding.constant(nil)
        ))
    }
    
    @MainActor @available(iOS 13.0, macOS 10.15, *)
    public func createTestComponent(
        exercises: [String],
        currentExercise: Binding<String>, // Changed to Binding
        currentRestSpeech: Binding<String?>?, // Added for dynamic updates
        user: UserDetails?,
        isLoading: Binding<Bool>,
        customParams: [String: Any] = [:],
        onMessageReceived: @escaping (WebViewMessage) -> Void
    ) -> AnyView {
        var allData = [
            "exercises": exercises,
            "currentExercise": currentExercise.wrappedValue
        ] as [String : Any]
        
        // Validation
        if !validateInput(
            apiKey: apiKey,
            companyName: companyName,
            userId: userId,
            customParams: allData.merging(customParams) { (_, new) in new }
        ) {
            // Specific error messages are printed within validateInput
            print("⚠️ KinesteX: Input validation failed. Component will not be created.")
            return AnyView(EmptyView())
        }
        
        // Construct data dictionary
        var data: [String: Any] = [
            "exercises": exercises,
            "currentExercise": currentExercise.wrappedValue
        ]
        if let user = user {
            data["age"] = user.age
            data["height"] = user.height
            data["weight"] = user.weight
            data["gender"] = genderString(user.gender)
            data["lifestyle"] = lifestyleString(user.lifestyle)
        }
        for (key, value) in customParams {
            data[key] = value
        }
        
        return AnyView(CameraView(
            apiKey: self.apiKey,
            companyName: self.companyName,
            userId: self.userId,
            url: self.baseURL.appendingPathComponent("test"),
            data: data,
            isLoading: isLoading,
            onMessageReceived: onMessageReceived,
            currentExercise: currentExercise,
            currentRestSpeech: currentRestSpeech ?? Binding.constant(nil)
        ))
    }
    
}
