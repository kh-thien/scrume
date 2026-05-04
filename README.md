# Scrume - Scrum Project Management for iOS

A native iOS application for managing Scrum projects. Built with SwiftUI for iOS 18.0+.

## Overview

Scrume is a Scrum project management tool for iOS that helps teams manage sprints, backlogs, and track progress. All data is encrypted locally on your device.

## Features

- Create and manage projects
- Team member management with role assignment
- Product backlog with priority and story points
- Sprint planning and management
- Scrum board with drag-and-drop
- Sprint reports and analytics
- Local encryption for all data
- Offline-first design

## Security

All project data is encrypted locally on your device using AES-256-GCM encryption. Encryption keys are stored securely in iOS Keychain. No data is sent to the cloud.

## Technologies

- SwiftUI (iOS 18.0+)
- Swift 5.9
- CryptoKit for encryption
- iOS Keychain for key storage
- Swift Charts for reports

## Requirements

- iOS 18.0 or later
- Xcode 16.0 or later

## Installation

```bash
git clone https://github.com/kh-thien/scrume.git
cd scrume
open scrume.xcodeproj
```

Then build and run in Xcode.

## License

MIT License

