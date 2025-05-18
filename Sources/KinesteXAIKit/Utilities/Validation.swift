    //
    //  Validation.swift
    //  
    //
    //  Created by Vladimir Shetnikov on 5/13/25.
    //

    import Foundation


    func genderString(_ gender: Gender) -> String {
        switch gender {
        case .Male: return "Male"
        case .Female: return "Female"
        case .Unknown: return "Unknown"
        }
    }

    func lifestyleString(_ lifestyle: Lifestyle) -> String {
        switch lifestyle {
        case .Sedentary: return "Sedentary"
        case .SlightlyActive: return "Slightly Active"
        case .Active: return "Active"
        case .VeryActive: return "Very Active"
        }
    }

    // Placeholder for validation function (define as needed)
    func containsDisallowedCharacters(_ string: String) -> Bool {
        let disallowed = CharacterSet(charactersIn: "<>\"'")
        return string.rangeOfCharacter(from: disallowed) != nil
    }

    func validateInput(
        apiKey: String,
        companyName: String,
        userId: String,
        customParams: [String: Any]
    ) -> Bool {
        if containsDisallowedCharacters(apiKey) {
            print("⚠️ KinesteX: Validation Error: apiKey contains disallowed characters.")
            return false
        }
        if containsDisallowedCharacters(companyName) {
            print("⚠️ KinesteX: Validation Error: companyName contains disallowed characters.")
            return false
        }
        if containsDisallowedCharacters(userId) {
            print("⚠️ KinesteX: Validation Error: userId contains disallowed characters.")
            return false
        }
        
        for (key, value) in customParams {
            if containsDisallowedCharacters(key) {
                print("⚠️ KinesteX: Validation Error: Custom parameter key '\(key)' contains disallowed characters.")
                return false
            }
            if let stringValue = value as? String, containsDisallowedCharacters(stringValue) {
                print("⚠️ KinesteX: Validation Error: Custom parameter value for key '\(key)' ('\(stringValue)') contains disallowed characters.")
                return false
            }
        }
        
        if apiKey.isEmpty {
            print("⚠️ KinesteX: Validation Error: apiKey cannot be empty.")
            return false
        }
        if userId.isEmpty {
            print("⚠️ KinesteX: Validation Error: userId cannot be empty.")
            return false
        }
        if companyName.isEmpty {
            print("⚠️ KinesteX: Validation Error: companyName cannot be empty.")
            return false
        }
        
        return true
    }
