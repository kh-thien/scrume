//
//  UserStory.swift
//  scrume
//
//  Created by NEIHT on 17/1/26.
//

import Foundation
import SwiftUI

// MARK: - Priority

enum Priority: Int, Codable, CaseIterable, Comparable, Identifiable {
    case low = 0
    case medium = 1
    case high = 2
    case critical = 3

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }

    var icon: String {
        switch self {
        case .low: return "arrow.down"
        case .medium: return "minus"
        case .high: return "arrow.up"
        case .critical: return "exclamationmark.2"
        }
    }

    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }

    static func < (lhs: Priority, rhs: Priority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Story Status (for Scrum Board)

enum StoryStatus: String, Codable, CaseIterable, Identifiable {
    case todo = "To Do"
    case inProgress = "In Progress"
    case done = "Done"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .todo: return "circle"
        case .inProgress: return "arrow.triangle.2.circlepath"
        case .done: return "checkmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .todo: return .gray
        case .inProgress: return .blue
        case .done: return .green
        }
    }

    var columnOrder: Int {
        switch self {
        case .todo: return 0
        case .inProgress: return 1
        case .done: return 2
        }
    }
}

// MARK: - User Story

struct UserStory: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var priority: Priority
    var storyPoints: Int
    var status: StoryStatus
    var assigneeIds: [UUID]
    var sprintId: UUID?
    var acceptanceCriteria: [AcceptanceCriterion]
    var tags: [String]
    let createdAt: Date
    var updatedAt: Date

    /// Valid story points (Fibonacci)
    static let validPoints = [1, 2, 3, 5, 8, 13, 21]

    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        priority: Priority = .medium,
        storyPoints: Int = 1,
        status: StoryStatus = .todo,
        assigneeIds: [UUID] = [],
        sprintId: UUID? = nil,
        acceptanceCriteria: [AcceptanceCriterion] = [],
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.priority = priority
        self.storyPoints = Self.validPoints.contains(storyPoints) ? storyPoints : 1
        self.status = status
        self.assigneeIds = assigneeIds
        self.sprintId = sprintId
        self.acceptanceCriteria = acceptanceCriteria
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    var completedCriteriaCount: Int {
        acceptanceCriteria.filter { $0.isCompleted }.count
    }

    var criteriaProgress: Double {
        guard !acceptanceCriteria.isEmpty else { return 0 }
        return Double(completedCriteriaCount) / Double(acceptanceCriteria.count)
    }
}

// MARK: - Sample Data

extension UserStory {
    static let sprintSamples: [UserStory] = [
        UserStory(
            title: "Create login screen", description: "As a user, I want to login",
            priority: .high, storyPoints: 5, status: .done,
            acceptanceCriteria: AcceptanceCriterion.samples),
        UserStory(
            title: "Display project list", description: "As a user, I want to see projects",
            priority: .high, storyPoints: 3, status: .inProgress,
            tags: ["UI", "Core"]),
        UserStory(
            title: "Create Scrum Board", description: "As a developer, I want Kanban board",
            priority: .critical, storyPoints: 8, status: .inProgress,
            tags: ["Feature"]),
        UserStory(
            title: "Add team members", description: "As a PO, I want to add members",
            priority: .medium, storyPoints: 3, status: .todo),
        UserStory(
            title: "Drag & Drop tasks", description: "As a user, I want to drag tasks",
            priority: .high, storyPoints: 5, status: .todo,
            tags: ["UX"]),
    ]

    static let backlogSamples: [UserStory] = [
        UserStory(
            title: "Dark Mode", description: "Support dark mode", priority: .low, storyPoints: 2,
            tags: ["UI"]),
        UserStory(
            title: "Export Report", description: "Export sprint report", priority: .medium,
            storyPoints: 5, tags: ["Feature"]),
        UserStory(
            title: "Burndown Chart", description: "Show burndown chart", priority: .low,
            storyPoints: 8, tags: ["Analytics"]),
    ]
}
