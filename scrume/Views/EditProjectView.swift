//
//  EditProjectView.swift
//  scrume
//
//  Created by NEIHT on 17/1/26.
//

import SwiftUI

/// Form to edit Project information
struct EditProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var project: Project
    @ObservedObject var viewModel: ProjectViewModel

    @State private var name: String = ""
    @State private var description: String = ""
    @State private var sprintDuration: Int = 2

    var body: some View {
        NavigationStack {
            Form {
                Section("Project Info") {
                    TextField("Project Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Sprint Duration") {
                    Picker("Weeks", selection: $sprintDuration) {
                        ForEach(1...4, id: \.self) { weeks in
                            Text("\(weeks) week\(weeks > 1 ? "s" : "")").tag(weeks)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Button("Delete Project", role: .destructive) {
                        viewModel.deleteProject(project)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        project.name = name.trimmingCharacters(in: .whitespaces)
                        project.description = description
                        project.sprintDurationWeeks = sprintDuration
                        project.updatedAt = Date()
                        viewModel.updateProject(project)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                name = project.name
                description = project.description
                sprintDuration = project.sprintDurationWeeks
            }
        }
    }
}

// MARK: - Preview

#Preview {
    EditProjectView(
        project: .constant(Project.sample),
        viewModel: ProjectViewModel()
    )
}
