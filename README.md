# KinesteXAIKit

A SwiftUI package that embeds KinesteX’s AI-powered camera workout experience as a WebView.  
Easily switch between multiple exercises at runtime, track loading state, and respond to messages from the JS layer.

---

## Installation

Use Swift Package Manager:

1. In Xcode, go to **File → Add Packages...**  
2. Enter your repo URL, e.g.  
   `https://github.com/KinesteX/KinesteX-AI-Kit.git`  
3. Select the version you want (e.g. from 1.0.0).

---

## Quick Start

1. Import the package  
   
   ```swift
   import KinesteXAIKit
   import SwiftUI
   ```

2. Initialize your kit (usually in your `App` or parent view):

   ```swift
   let kit = KinesteXAIKit(
     apiKey: "YOUR_API_KEY",
     companyName: "MyCompany",
     userId: "user-123"
   )
   ```

3. Create a view that drives the camera workout:

   ```swift
   struct WorkoutView: View {
     // 1) The list of exercises
     let exercises = ["squat", "pushup", "plank"]
     
     // 2) Bindings required by the kit
     @State private var currentExercise = "squat"
     @State private var currentRestSpeech: String? = nil
     @State private var isLoading = false
     
     // 3) Your kit instance
     let kit = KinesteXAIKit(
       apiKey: "YOUR_API_KEY",
       companyName: "MyCompany",
       userId: "user-123"
     )
   
     var body: some View {
       VStack(spacing: 16) {
         // Embed the camera view
         kit.createCameraView(
           exercises: exercises,
           currentExercise: $currentExercise,
           currentRestSpeech: $currentRestSpeech,
           user: nil,                      // or your UserDetails
           isLoading: $isLoading
         ) { message in
           // Handle messages from the WebView
           print("JS Message:", message)
         }
         .frame(height: 400)
   
         // Display or change the current exercise
         Text("Now: \(currentExercise)")
           .font(.headline)
   
         Button("Next Exercise") {
           guard let idx = exercises.firstIndex(of: currentExercise) else { return }
           currentExercise = exercises[(idx + 1) % exercises.count]
         }
       }
       .padding()
     }
   }
   ```

---

## How It Works

- **Bindings**  
  - `currentExercise: Binding<String>`: Changing this state will update the current exercise being tracked and will provide necessary feedback
  - `currentRestSpeech: Binding<String?>`: Optional state to control audio during rest being played
  - `isLoading: Binding<Bool>`: Tracks the WebView’s loading state (black screen in the beginning).

- **Dynamic Updates**  
  Just mutate your `@State currentExercise` and the JS side will switch drills in real time.

- **Cleanup**  
  When the SwiftUI view unmounts or your `KinesteXAIKit` deinitializes you’ll see in the console:

  ```
  🗑️ KinesteX: cleaning up...
  🗑️ KinesteX: Coordinator deinitialized
  ✅ KinesteX: cleaned up and set webView to nil
  🗑️ KinesteX: WebViewState deinitialized
  🗑️ KinesteX: WebView deinitialized
  ```

---

## API Overview

```swift
// Camera-based workout
func createCameraView(
  exercises: [String],
  currentExercise: Binding<String>,
  currentRestSpeech: Binding<String?>? = nil,
  user: UserDetails?,
  isLoading: Binding<Bool>,
  customParams: [String:Any] = [:],
  onMessageReceived: @escaping (WebViewMessage) -> Void
) -> AnyView

// Preconfigured plan, workout, challenge, experience, leaderboard views:
// createPlanView(plan:), createWorkoutView(workout:), createChallengeView(...), etc.
```

Each `create…View` under the hood:
1. Merges your `defaultData` + `user` profile + `customParams`  
2. Validates inputs  
3. Instantiates a `KinestexView` wrapping a `WKWebView`

---

Enjoy seamless, AI-driven workout guidance in SwiftUI!  
Feel free to open issues or PRs on GitHub.
