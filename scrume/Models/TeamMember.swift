//
//  TeamMember.swift
//  scrume
//
//  Created by NEIHT on 17/1/26.
//

import Foundation
import SwiftUI

// MARK: - Scrum Role

enum ScrumRole: String, Codable, CaseIterable, Identifiable {
    case productOwner = "Product Owner"
    case scrumMaster = "Scrum Master"
    case developer = "Developer"
    case designer = "Designer"
    case tester = "QA Tester"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .productOwner: return "star.fill"
        case .scrumMaster: return "person.badge.shield.checkmark.fill"
        case .developer: return "chevron.left.forwardslash.chevron.right"
        case .designer: return "paintbrush.fill"
        case .tester: return "checkmark.seal.fill"
        }
    }

    var color: Color {
        switch self {
        case .productOwner: return .orange
        case .scrumMaster: return .purple
        case .developer: return .blue
        case .designer: return .pink
        case .tester: return .green
        }
    }
}

// MARK: - Team Member

struct TeamMember: Identifiable, Codable {
    let id: UUID
    var name: String
    var email: String
    var role: ScrumRole
    var avatarColor: String  // Hex color

    init(
        id: UUID = UUID(),
        name: String,
        email: String = "",
        role: ScrumRole = .developer,
        avatarColor: String = "007AFF"
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.role = role
        self.avatarColor = avatarColor
    }

    /// Initials for avatar
    var initials: String {
        let parts = name.components(separatedBy: " ")
        if parts.count >= 2 {
            return "\(parts.first?.prefix(1) ?? "")\(parts.last?.prefix(1) ?? "")".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

// MARK: - Sample Data

extension TeamMember {
    static let samples: [TeamMember] = [
        TeamMember(
            name: "John Smith", email: "john@email.com", role: .productOwner, avatarColor: "FF6B6B"
        ),
        TeamMember(
            name: "Sarah Johnson", email: "sarah@email.com", role: .scrumMaster,
            avatarColor: "4ECDC4"),
        TeamMember(
            name: "Mike Chen", email: "mike@email.com", role: .developer, avatarColor: "45B7D1"),
        TeamMember(
            name: "Emily Davis", email: "emily@email.com", role: .designer, avatarColor: "96CEB4"),
        TeamMember(
            name: "Alex Wilson", email: "alex@email.com", role: .tester, avatarColor: "FFEAA7"),
    ]
}
