# KinesteXAIKit Swift Package Setup Guide

## 1. Create the Package Directory Structure

Your package should be organized like this:

```
KinesteXAIKit/
├── Package.swift                    # Package manifest (root level)
├── README.md                       # Documentation
├── Sources/                        # Source code directory
│   └── KinesteXAIKit/             # Target directory
│       ├── KinesteXAIKit.swift    # Main SDK file
│       ├── KinestexView.swift     # WebView component
│       ├── APIService.swift       # API service
│       ├── Enums.swift            # Enums and types
│       ├── UserDetails.swift      # User models
│       ├── Models/                # Data models (optional subfolder)
│       │   ├── WorkoutModel.swift
│       │   ├── ExerciseModel.swift
│       │   └── PlanModel.swift
│       └── Internal/              # Internal utilities (optional)
│           ├── Validation.swift
│           └── WebViewState.swift
├── Tests/                         # Test directory
│   └── KinesteXAIKitTests/        # Test target
│       ├── KinesteXAIKitTests.swift
│       ├── APIServiceTests.swift
│       └── ModelsTests.swift
└── Examples/                      # Example usage (optional)
    └── ExampleApp/
```

## 2. Terminal Commands to Create Structure

Run these commands in Terminal:

```bash
# Create main package directory
mkdir KinesteXAIKit
cd KinesteXAIKit

# Create Sources structure
mkdir -p Sources/KinesteXAIKit/Models
mkdir -p Sources/KinesteXAIKit/Internal

# Create Tests structure  
mkdir -p Tests/KinesteXAIKitTests

# Create Examples (optional)
mkdir -p Examples/ExampleApp

# Create Package.swift at root level
touch Package.swift
touch README.md
```

## 3. Alternative: Use Xcode to Create Package

1. Open Xcode
2. File → New → Package...
3. Choose location and name "KinesteXAIKit"
4. Xcode will create the structure automatically