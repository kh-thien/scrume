# 🏃 Scrume - Scrum Project Management for iOS

<p align="center">
  <img src="https://img.shields.io/badge/iOS-18.0+-blue?style=for-the-badge&logo=apple" alt="iOS 18.0+">
  <img src="https://img.shields.io/badge/Swift-5.9-orange?style=for-the-badge&logo=swift" alt="Swift 5.9">
  <img src="https://img.shields.io/badge/SwiftUI-5-purple?style=for-the-badge&logo=swift" alt="SwiftUI 5">
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="MIT License">
</p>

<p align="center">
  <b>A native iOS application for Agile/Scrum project management with enterprise-grade security</b>
</p>

---

## 📱 Overview

**Scrume** is a fully native iOS application built with SwiftUI for managing Scrum projects. It provides a complete toolkit for Product Owners, Scrum Masters, and Development Teams to manage sprints, backlogs, and track project progress - all with **military-grade encryption** for data protection.

### ✨ Key Highlights

- 🔐 **AES-256-GCM Encryption** - All data encrypted at rest
- 🔑 **Keychain Integration** - Encryption keys stored securely in iOS Keychain
- 📱 **100% Native SwiftUI** - Optimized for iOS, no web views
- 🎨 **Modern UI/UX** - Floating tab bar with glass morphism effect
- 📊 **Real-time Charts** - Burndown, velocity tracking with Swift Charts
- 🚀 **Offline-First** - Works completely offline

---

## 🏗️ Architecture

### Design Pattern: **MVVM (Model-View-ViewModel)**

```
┌─────────────────────────────────────────────────────────────┐
│                         VIEWS                                │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌────────┐ │
│  │  Home   │ │  Board  │ │ Backlog │ │ Reports │ │Project │ │
│  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘ └───┬────┘ │
│       │           │           │           │          │       │
│       └───────────┴─────┬─────┴───────────┴──────────┘       │
│                         │                                     │
│                         ▼                                     │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              ProjectViewModel                         │   │
│  │   @Published projects: [Project]                     │   │
│  │   @Published selectedProject: Project?               │   │
│  │   + CRUD Operations                                  │   │
│  └──────────────────────┬───────────────────────────────┘   │
│                         │                                     │
│                         ▼                                     │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              DataManager (Singleton)                  │   │
│  │   🔐 AES-256-GCM Encryption                          │   │
│  │   🔑 Keychain Key Storage                            │   │
│  │   📁 File-based Persistence                          │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Project Structure

```
scrume/
├── 📁 Models/                    # Data Models
│   ├── Project.swift             # Project entity
│   ├── Sprint.swift              # Sprint + SprintStatus enum
│   ├── UserStory.swift           # User Story + Priority + StoryStatus
│   ├── TeamMember.swift          # Team member + ScrumRole enum
│   └── AcceptanceCriterion.swift # Acceptance criteria for stories
│
├── 📁 ViewModels/                # Business Logic
│   └── ProjectViewModel.swift    # Main ViewModel (@MainActor)
│
├── 📁 Views/                     # UI Components
│   ├── MainTabView.swift         # Custom floating tab bar
│   ├── HomeTabView.swift         # Dashboard overview
│   ├── BoardTabView.swift        # Scrum Board wrapper
│   ├── ScrumBoardView.swift      # 3-column Kanban board
│   ├── BacklogTabView.swift      # Product Backlog wrapper
│   ├── BacklogListView.swift     # Backlog management
│   ├── ReportsTabView.swift      # Charts & analytics
│   ├── ProjectTabView.swift      # Project settings
│   ├── SprintListView.swift      # All sprints list
│   ├── SprintDetailView.swift    # Sprint details
│   ├── UserStoryDetailView.swift # Story details
│   ├── SplashScreenView.swift    # App launch screen
│   └── 📁 Components/            # Reusable components
│       └── AssigneesAvatarStack.swift
│
├── 📁 Services/                  # Data Layer
│   └── DataManager.swift         # Encrypted storage manager
│
├── 📁 Theme/                     # Design System
│   └── AppTheme.swift            # Colors, fonts, styles
│
├── 📁 Assets.xcassets/           # Images & Colors
├── scrumeApp.swift               # App entry point
└── ContentView.swift             # Root view
```

---

## 🚀 MVP Features

### 1. 📊 Project Management
- ✅ Create, edit, delete projects
- ✅ Multiple projects support
- ✅ Project switching
- ✅ Configurable sprint duration (1-4 weeks)

### 2. 👥 Team Management
- ✅ Add/remove team members
- ✅ Role assignment (Product Owner, Scrum Master, Developer)
- ✅ Avatar color customization
- ✅ Multiple assignees per story

### 3. 📝 Product Backlog
- ✅ Create user stories with description
- ✅ Priority levels (Low, Medium, High, Critical)
- ✅ Story points estimation (Fibonacci: 1-21)
- ✅ Acceptance criteria
- ✅ Tags support
- ✅ Search & filter
- ✅ Drag to reorder

### 4. 🏃 Sprint Management
- ✅ Create sprints with goals
- ✅ Sprint planning (add stories from backlog)
- ✅ Start/Complete sprint actions
- ✅ Sprint status tracking (Planning → Active → Completed)
- ✅ Days remaining indicator

### 5. 📋 Scrum Board (Kanban)
- ✅ 3-column layout: To Do | In Progress | Done
- ✅ Drag & drop stories between columns
- ✅ Real-time progress tracking
- ✅ Visual story cards with priority indicators

### 6. 📈 Reports & Analytics
- ✅ **Burndown Chart** - Track remaining work
- ✅ **Velocity Chart** - Sprint-over-sprint comparison
- ✅ **Sprint Summary** - Completion statistics
- ✅ Quick stats dashboard

### 7. 🔐 Security & Privacy
- ✅ AES-256-GCM encryption
- ✅ Keychain-protected encryption keys
- ✅ Complete file protection
- ✅ Offline data storage (no cloud dependency)
- ✅ Data export/import capability

---

## 🔐 Security Architecture

### Encryption Flow

```
┌────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   User Data    │────▶│  JSON Encoding   │────▶│  AES-256-GCM    │
│   (Projects)   │     │                  │     │   Encryption    │
└────────────────┘     └──────────────────┘     └────────┬────────┘
                                                         │
                                                         ▼
┌────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   iOS Keychain │◀────│  256-bit Key     │     │  Encrypted File │
│   (Secure)     │     │   Generation     │     │   (.encrypted)  │
└────────────────┘     └──────────────────┘     └─────────────────┘
```

### Security Features

| Feature | Implementation |
|---------|----------------|
| **Encryption Algorithm** | AES-256-GCM (CryptoKit) |
| **Key Storage** | iOS Keychain with `kSecAttrAccessibleAfterFirstUnlock` |
| **File Protection** | `.completeFileProtection` on write |
| **Data Location** | App's Documents directory (sandboxed) |
| **Key Generation** | `SymmetricKey(size: .bits256)` |
| **Migration** | Automatic from UserDefaults to encrypted storage |

### Why This Matters

- 🛡️ **AES-256-GCM** - Same encryption used by governments and banks
- 🔑 **Keychain** - Hardware-backed security on devices with Secure Enclave
- 📱 **Sandboxed** - Data isolated from other apps
- 🚫 **No Cloud** - Your data never leaves your device

---

## 🛠️ Technologies Used

### Core Frameworks

| Technology | Usage |
|------------|-------|
| **SwiftUI** | Entire UI layer, declarative views |
| **Swift 5.9** | Modern Swift features, async/await ready |
| **CryptoKit** | AES-256-GCM encryption |
| **Security Framework** | Keychain access |
| **Swift Charts** | Burndown & velocity charts |
| **Combine** | Reactive data binding via `@Published` |

### SwiftUI Features Utilized

```swift
// Property Wrappers
@StateObject          // ViewModel lifecycle
@ObservedObject       // Observing shared state
@Published            // Reactive properties
@Binding              // Two-way data flow
@State                // Local view state
@MainActor            // Main thread safety

// Modern SwiftUI APIs
NavigationStack       // iOS 16+ navigation
TabView               // Tab-based navigation
.sheet()              // Modal presentations
.alert()              // System alerts
.searchable()         // Native search
.swipeActions()       // Swipe gestures
.contextMenu()        // Long-press menus
.symbolEffect()       // SF Symbol animations

// UI Components
List                  // Performant lists
ScrollView            // Scrollable content
Form                  // Settings/input forms
Section               // Grouped content
Charts (Swift Charts) // Data visualization
.ultraThinMaterial    // Glass morphism effect
```

### Design Patterns

- **MVVM** - Clear separation of concerns
- **Singleton** - DataManager for centralized storage
- **Repository Pattern** - Abstracted data operations
- **Dependency Injection** - ViewModel passed to views

---

## 📲 Installation

### Requirements

- iOS 18.0+
- Xcode 16.0+
- Swift 5.9+

### Build Steps

```bash
# Clone the repository
git clone https://github.com/phankhacthiennguyen/scrume.git

# Open in Xcode
cd scrume
open scrume.xcodeproj

# Build and Run (⌘ + R)
# Select your target device/simulator
```

### No Dependencies

Scrume uses **zero external dependencies** - only Apple's native frameworks:
- No CocoaPods
- No Swift Package Manager dependencies
- No third-party libraries

---

## 🎨 UI/UX Design

### Custom Floating Tab Bar

```swift
// Modern floating tab bar with:
- RoundedRectangle(cornerRadius: 25)  // Rounded corners
- .ultraThinMaterial                   // Glass blur effect
- .shadow()                            // Depth
- Spring animations                    // Smooth transitions
- Scale effect on selection            // Visual feedback
```

### Color System

- **Primary**: System Blue
- **Backgrounds**: System Grouped Background
- **Materials**: Ultra Thin Material (glass effect)
- **Semantic Colors**: Green (success), Orange (warning), Red (critical)

### Typography

- SF Pro (System default)
- Dynamic Type support
- Semantic font styles (.title, .headline, .body, .caption)

---

## 🗺️ Roadmap

### Planned Features

- [ ] 🌙 Dark Mode optimization
- [ ] 📤 iCloud Sync
- [ ] 📊 Export to PDF/CSV
- [ ] ⏰ Sprint reminders (Local Notifications)
- [ ] 📱 iPad support
- [ ] ⌚ Apple Watch companion
- [ ] 🔗 Deep linking
- [ ] 🌍 Localization (Multiple languages)

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**Khac Thien Nguyen (NEIHT)**

- GitHub: [@phankhacthiennguyen](https://github.com/phankhacthiennguyen)

---

## 🙏 Acknowledgments

- Apple's [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Scrum Guide](https://scrumguides.org/) for Agile methodology reference
- SwiftUI community for inspiration

---

<p align="center">
  Made with ❤️ using SwiftUI
</p>
