//
//  WorkoutSequenceExercise.swift
//  KinesteXAIKit
//
//  Created by Gurbanmyrat Ataballyyev on 16.01.2026.
//

public struct WorkoutSequenceExercise {
    let exerciseId: String
    let reps: Int?
    let duration: Int?
    let includeRestPeriod: Bool
    let restDuration: Int
    
    public init(
        exerciseId: String,
        reps: Int? = nil,
        duration: Int? = nil,
        includeRestPeriod: Bool = false,
        restDuration: Int = 0
    ) {
        self.exerciseId = exerciseId
        self.reps = reps
        self.duration = duration
        self.includeRestPeriod = includeRestPeriod
        self.restDuration = restDuration
    }
    
    func toMap() -> [String: Any] {
        var map: [String: Any] = [
            "exerciseId": exerciseId,
            "includeRestPeriod": includeRestPeriod,
            "restDuration": restDuration
        ]
        
        // Only include non-nil values
        if let reps = reps {
            map["reps"] = reps
        }
        
        if let duration = duration {
            map["duration"] = duration
        }
        
        return map
    }
}
