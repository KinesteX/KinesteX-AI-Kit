public enum Gender {
       case Male
       case Female
       case Unknown
   }

   public enum Lifestyle {
       case Sedentary
       case SlightlyActive
       case Active
       case VeryActive
   }

   public struct UserDetails {
       var age: Int
       var height: Int
       var weight: Int
       var gender: Gender
       var lifestyle: Lifestyle
       
       public init(age: Int, height: Int, weight: Int, gender: Gender, lifestyle: Lifestyle) {
           self.age = age
           self.height = height
           self.weight = weight
           self.gender = gender
           self.lifestyle = lifestyle
       }
   }

public enum PlanCategory: Equatable {
    case Cardio
    case WeightManagement
    case Strength
    case Rehabilitation
    case Custom(String)

    // Optional: Implement the Equatable conformance manually if needed
    public static func == (lhs: PlanCategory, rhs: PlanCategory) -> Bool {
        switch (lhs, rhs) {
        case (.Cardio, .Cardio),
             (.WeightManagement, .WeightManagement),
             (.Strength, .Strength),
             (.Rehabilitation, .Rehabilitation):
            return true
        case let (.Custom(lhsValue), .Custom(rhsValue)):
            return lhsValue == rhsValue
        default:
            return false
        }
    }
}
