//
//  Project.swift
//  scrume
//
//  Created by NEIHT on 17/1/26.
//

import Foundation

// MARK: - Project Model

/// Project - Represents a Scrum project
struct Project: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var description: String
    var sprintDurationWeeks: Int  // 1-4 weeks
    var members: [TeamMember]
    var sprints: [Sprint]
    var backlog: [UserStory]
    let createdAt: Date
    var updatedAt: Date

    // Equatable - compare by ID
    static func == (lhs: Project, rhs: Project) -> Bool {
        lhs.id == rhs.id && lhs.updatedAt == rhs.updatedAt
    }

    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        sprintDurationWeeks: Int = 2,
        members: [TeamMember] = [],
        sprints: [Sprint] = [],
        backlog: [UserStory] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.sprintDurationWeeks = min(max(sprintDurationWeeks, 1), 4)
        self.members = members
        self.sprints = sprints
        self.backlog = backlog
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    var activeSprint: Sprint? {
        sprints.first { $0.status == .active }
    }

    var totalBacklogPoints: Int {
        backlog.reduce(0) { $0 + $1.storyPoints }
    }
}

// MARK: - Sample Data

extension Project {
    static let sample = Project(
        name: "Scrume App",
        description: "Scrum project management application",
        sprintDurationWeeks: 2,
        members: TeamMember.samples,
        sprints: [Sprint.sample],
        backlog: UserStory.backlogSamples
    )

    static let samples: [Project] = [
        sample,
        Project(
            name: "E-Commerce App", description: "Online shopping application",
            sprintDurationWeeks: 3),
        Project(name: "Chat App", description: "Messaging application", sprintDurationWeeks: 1),
    ]
}
