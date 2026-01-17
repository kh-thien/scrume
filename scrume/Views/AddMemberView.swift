//
//  AddMemberView.swift
//  scrume
//
//  Created by NEIHT on 17/1/26.
//

import SwiftUI

/// Form to add new team member to Project
struct AddMemberView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var project: Project
    @ObservedObject var viewModel: ProjectViewModel

    @State private var name = ""
    @State private var email = ""
    @State private var role: ScrumRole = .developer
    @State private var selectedColor = "007AFF"

    private let avatarColors = [
        "FF6B6B", "4ECDC4", "45B7D1", "96CEB4", "FFEAA7",
        "DDA0DD", "98D8C8", "F7DC6F", "BB8FCE", "85C1E9",
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Information") {
                    TextField("Member Name", text: $name)
                    TextField("Email (optional)", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                }

                Section("Role") {
                    Picker("Role", selection: $role) {
                        ForEach(ScrumRole.allCases) { role in
                            Label(role.rawValue, systemImage: role.icon)
                                .tag(role)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section("Avatar Color") {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12
                    ) {
                        ForEach(avatarColors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 44, height: 44)
                                .overlay {
                                    if selectedColor == color {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.white)
                                            .fontWeight(.bold)
                                    }
                                }
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Preview
                Section("Preview") {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: selectedColor))
                                .frame(width: 50, height: 50)

                            Text(previewInitials)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(name.isEmpty ? "Member Name" : name)
                                .font(.headline)

                            Label(role.rawValue, systemImage: role.icon)
                                .font(.caption)
                                .foregroundStyle(role.color)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Add Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addMember()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var previewInitials: String {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return "?" }

        let parts = trimmedName.components(separatedBy: " ")
        if parts.count >= 2 {
            return "\(parts.first?.prefix(1) ?? "")\(parts.last?.prefix(1) ?? "")".uppercased()
        }
        return String(trimmedName.prefix(2)).uppercased()
    }

    // MARK: - Actions

    private func addMember() {
        let member = TeamMember(
            name: name.trimmingCharacters(in: .whitespaces),
            email: email.trimmingCharacters(in: .whitespaces),
            role: role,
            avatarColor: selectedColor
        )

        project.members.append(member)
        viewModel.updateProject(project)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    AddMemberView(
        project: .constant(Project.sample),
        viewModel: ProjectViewModel()
    )
}
