//
//  WebViewMessage.swift
//  
//
//  Created by Vladimir Shetnikov on 5/13/25.
//


public enum KinestexMessage {
    case kinestex_launched([String: Any])
    case finished_workout([String: Any])
    case error_occurred([String: Any])
    case exercise_completed([String: Any])
    case exit_kinestex([String: Any])
    case workout_opened([String: Any])
    case workout_started([String: Any])
    case plan_unlocked([String: Any])
    case custom_type([String: Any])
    case reps([String: Any])
    case mistake([String: Any])
    case left_camera_frame([String: Any])
    case returned_camera_frame([String: Any])
    case workout_overview([String: Any])
    case exercise_overview([String: Any])
    case workout_completed([String: Any])
    case kinestex_loaded([String: Any])
    case all_resources_loaded([String: Any])
}
