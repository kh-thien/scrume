//
//  Sprint.swift
//  scrume
//
//  Created by NEIHT on 17/1/26.
//

import Foundation
import SwiftUI

// MARK: - Sprint Status

enum SprintStatus: String, Codable, CaseIterable, Identifiable {
    case planning = "Planning"
    case active = "Active"
    case completed = "Completed"
    case cancelled = "Cancelled"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .planning: return "pencil.and.list.clipboard"
        case .active: return "play.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .planning: return .orange
        case .active: return .blue
        case .completed: return .green
        case .cancelled: return .red
        }
    }
}

// MARK: - Sprint

struct Sprint: Identifiable, Codable {
    let id: UUID
    var name: String
    var goal: String
    var startDate: Date?
    var endDate: Date?
    var status: SprintStatus
    var stories: [UserStory]

    init(
        id: UUID = UUID(),
        name: String,
        goal: String = "",
        startDate: Date? = nil,
        endDate: Date? = nil,
        status: SprintStatus = .planning,
        stories: [UserStory] = []
    ) {
        self.id = id
        self.name = name
        self.goal = goal
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.stories = stories
    }

    // MARK: - Computed Properties

    var totalStoryPoints: Int {
        stories.reduce(0) { $0 + $1.storyPoints }
    }

    var completedStoryPoints: Int {
        stories.filter { $0.status == .done }.reduce(0) { $0 + $1.storyPoints }
    }

    var progressPercentage: Double {
        guard totalStoryPoints > 0 else { return 0 }
        return (Double(completedStoryPoints) / Double(totalStoryPoints)) * 100
    }

    var todoStories: [UserStory] { stories.filter { $0.status == .todo } }
    var inProgressStories: [UserStory] { stories.filter { $0.status == .inProgress } }
    var doneStories: [UserStory] { stories.filter { $0.status == .done } }
}

// MARK: - Sample Data

extension Sprint {
    static let sample = Sprint(
        name: "Sprint 1",
        goal: "Complete core features",
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()),
        status: .active,
        stories: UserStory.sprintSamples
    )
}
