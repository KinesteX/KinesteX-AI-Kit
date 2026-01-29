import Foundation

/// ContentType defines the types of content that can be fetched from the API.
public enum ContentType: String, CaseIterable, Identifiable {
    case workout = "Workout"
    case plan = "Plan"
    case exercise = "Exercise"
    
    public var id: String { self.rawValue }
}

/// BodyPart defines the different body parts that can be targeted by exercises.
public enum BodyPart: String, CaseIterable, Identifiable {
    case abs = "Abs"
    case biceps = "Biceps"
    case calves = "Calves"
    case chest = "Chest"
    case externalOblique = "External Oblique"
    case forearms = "Forearms"
    case glutes = "Glutes"
    case neck = "Neck"
    case quads = "Quads"
    case shoulders = "Shoulders"
    case triceps = "Triceps"
    case hamstrings = "Hamstrings"
    case lats = "Lats"
    case lowerBack = "Lower Back"
    case traps = "Traps"
    case fullBody = "Full Body"
    
    public var id: String { self.rawValue }
}

/// APIContentResult is an enum that represents the result of an API request.
public enum APIContentResult {
    case workouts(WorkoutsResponse)
    case workout(WorkoutModel)
    case plans(PlansResponse)
    case plan(PlanModel)
    case exercises(ExercisesResponse)
    case exercise(ExerciseModel)
    case error(String)
    case rawData([String: Any], String?) // Raw data with optional error message
}

/// AdminContentType defines the types of content for admin functionality.
public enum AdminContentType: String, CaseIterable, Identifiable {
    case workout = "workout"
    case plan = "plan"
    case exercise = "exercise"
    
    public var id: String { self.rawValue }
    
    /// Returns the URL segment for the admin content type
    public var segment: String {
        switch self {
        case .workout:
            return "workouts"
        case .plan:
            return "plans"
        case .exercise:
            return "exercises"
        }
    }
}

