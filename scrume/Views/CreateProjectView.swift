//
//  CreateProjectView.swift
//  scrume
//
//  Created by NEIHT on 17/1/26.
//

import SwiftUI

/// View để tạo project mới
struct CreateProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProjectViewModel

    @State private var name = ""
    @State private var description = ""
    @State private var sprintDurationWeeks = 2

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Project Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Project Info")
                }

                Section {
                    Picker("Sprint Duration", selection: $sprintDurationWeeks) {
                        Text("1 week").tag(1)
                        Text("2 weeks").tag(2)
                        Text("3 weeks").tag(3)
                        Text("4 weeks").tag(4)
                    }
                } header: {
                    Text("Settings")
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createProject()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func createProject() {
        viewModel.createProject(
            name: name,
            description: description,
            sprintDuration: sprintDurationWeeks
        )
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    CreateProjectView(viewModel: ProjectViewModel())
}
