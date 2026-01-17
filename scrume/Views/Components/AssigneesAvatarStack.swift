//
//  AssigneesAvatarStack.swift
//  scrume
//
//  Created by NEIHT on 17/1/26.
//

import SwiftUI

/// Hiển thị stack avatars cho nhiều assignees
struct AssigneesAvatarStack: View {
    let assigneeIds: [UUID]
    let members: [TeamMember]
    var size: CGFloat = 24
    var maxDisplay: Int = 3

    private var assignees: [TeamMember] {
        members.filter { assigneeIds.contains($0.id) }
    }

    var body: some View {
        HStack(spacing: -(size * 0.3)) {
            ForEach(assignees.prefix(maxDisplay)) { member in
                Circle()
                    .fill(Color(hex: member.avatarColor))
                    .frame(width: size, height: size)
                    .overlay {
                        Text(member.initials)
                            .font(.system(size: size * 0.4, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .overlay {
                        Circle().stroke(Color(.systemBackground), lineWidth: 2)
                    }
            }

            if assignees.count > maxDisplay {
                Circle()
                    .fill(Color.gray.opacity(0.8))
                    .frame(width: size, height: size)
                    .overlay {
                        Text("+\(assignees.count - maxDisplay)")
                            .font(.system(size: size * 0.35, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .overlay {
                        Circle().stroke(Color(.systemBackground), lineWidth: 2)
                    }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AssigneesAvatarStack(
            assigneeIds: [UUID(), UUID(), UUID()],
            members: [
                TeamMember(name: "Alice", role: .developer, avatarColor: "FF6B6B"),
                TeamMember(name: "Bob", role: .developer, avatarColor: "4ECDC4"),
                TeamMember(name: "Charlie", role: .tester, avatarColor: "45B7D1"),
            ],
            size: 32
        )

        AssigneesAvatarStack(
            assigneeIds: [],
            members: [],
            size: 24
        )
    }
    .padding()
}
