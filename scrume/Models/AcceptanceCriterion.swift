//
//  AcceptanceCriterion.swift
//  scrume
//
//  Created by NEIHT on 17/1/26.
//

import Foundation

// MARK: - Acceptance Criterion

/// Tiêu chí chấp nhận cho User Story
struct AcceptanceCriterion: Identifiable, Codable {
    let id: UUID
    var description: String
    var isCompleted: Bool
    let createdAt: Date

    init(
        id: UUID = UUID(),
        description: String,
        isCompleted: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.description = description
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}

// MARK: - Sample Data

extension AcceptanceCriterion {
    static let samples: [AcceptanceCriterion] = [
        AcceptanceCriterion(description: "User có thể nhập email và password", isCompleted: true),
        AcceptanceCriterion(
            description: "Validation hiển thị khi input không hợp lệ", isCompleted: true),
        AcceptanceCriterion(
            description: "Loading indicator hiển thị khi đang login", isCompleted: false),
    ]
}
