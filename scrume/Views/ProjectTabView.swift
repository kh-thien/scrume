//
//  ProjectTabView.swift
//  scrume
//
//  Created by NEIHT on 17/1/26.
//

import SwiftUI

/// Project Tab - Project info, team, and sprints management
struct ProjectTabView: View {
    @Binding var project: Project
    @ObservedObject var viewModel: ProjectViewModel

    @State private var showEditProject = false
    @State private var showAddMember = false
    @State private var showSwitchProject = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Project Section
                Section {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.gradient)
                                .frame(width: 50, height: 50)

                            Text(String(project.name.prefix(1)))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(project.name)
                                .font(.headline)
                            Text(
                                project.description.isEmpty ? "No description" : project.description
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        }
                    }
                    .padding(.vertical, 4)

                    Button {
                        showEditProject = true
                    } label: {
                        Label("Edit Project", systemImage: "pencil")
                    }

                    Button {
                        showSwitchProject = true
                    } label: {
                        Label("Switch Project", systemImage: "arrow.left.arrow.right")
                    }
                } header: {
                    Text("Project")
                }

                // MARK: - Team Section
                Section {
                    ForEach(project.members) { member in
                        TeamMemberRowView(member: member)
                    }
                    .onDelete(perform: deleteMember)

                    Button {
                        showAddMember = true
                    } label: {
                        Label("Add Member", systemImage: "person.badge.plus")
                    }
                } header: {
                    Text("Team (\(project.members.count))")
                }

                // MARK: - Sprints Section
                Section {
                    NavigationLink {
                        SprintListView(project: $project, viewModel: viewModel)
                    } label: {
                        HStack {
                            Label("All Sprints", systemImage: "arrow.triangle.2.circlepath")
                            Spacer()
                            Text("\(project.sprints.count)")
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let activeSprint = project.activeSprint {
                        HStack {
                            Label("Active", systemImage: "play.circle.fill")
                                .foregroundStyle(.blue)
                            Spacer()
                            Text(activeSprint.name)
                                .foregroundStyle(.secondary)
                        }
                    }

                    let completedCount = project.sprints.filter { $0.status == .completed }.count
                    HStack {
                        Label("Completed", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Spacer()
                        Text("\(completedCount)")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Sprints")
                }

                // MARK: - Info Section
                Section {
                    LabeledContent("Sprint Duration") {
                        Text("\(project.sprintDurationWeeks) weeks")
                    }

                    LabeledContent("Total Backlog Points") {
                        Text("\(project.totalBacklogPoints)")
                    }

                    LabeledContent("Created") {
                        Text(project.createdAt, style: .date)
                    }
                } header: {
                    Text("Info")
                }
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 80)
            }
            .navigationTitle("Project")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $showEditProject) {
                EditProjectView(project: $project, viewModel: viewModel)
            }
            .sheet(isPresented: $showAddMember) {
                AddMemberView(project: $project, viewModel: viewModel)
            }
            .sheet(isPresented: $showSwitchProject) {
                ProjectPickerSheet(viewModel: viewModel, currentProject: $project)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(viewModel: viewModel)
            }
        }
    }

    private func deleteMember(at offsets: IndexSet) {
        project.members.remove(atOffsets: offsets)
        viewModel.updateProject(project)
    }
}

// MARK: - Settings View (Sheet)

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProjectViewModel

    @State private var showClearDataConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Data Management Section
                Section {
                    Button(role: .destructive) {
                        showClearDataConfirmation = true
                    } label: {
                        Label("Clear All Data", systemImage: "trash.fill")
                    }
                } header: {
                    Text("Data")
                } footer: {
                    Text("This will delete all projects, sprints, and stories permanently.")
                }

                // MARK: - Future Features (Placeholders)
                Section {
                    Label("Export Data", systemImage: "square.and.arrow.up")
                        .foregroundStyle(.secondary)

                    Label("Import Data", systemImage: "square.and.arrow.down")
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Backup")
                } footer: {
                    Text("Coming soon - Export and import your data.")
                }

                // MARK: - App Info
                Section {
                    LabeledContent("Version") {
                        Text("1.0.0")
                    }

                    LabeledContent("Build") {
                        Text("1")
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Clear All Data?", isPresented: $showClearDataConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    viewModel.clearAllData()
                    dismiss()
                }
            } message: {
                Text(
                    "This action cannot be undone. All projects, sprints, and stories will be permanently deleted."
                )
            }
        }
    }
}

// MARK: - Project Picker Sheet

struct ProjectPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProjectViewModel
    @Binding var currentProject: Project

    @State private var showCreateProject = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.projects) { proj in
                    Button {
                        if let index = viewModel.projects.firstIndex(where: { $0.id == proj.id }) {
                            currentProject = viewModel.projects[index]
                        }
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(proj.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Text(
                                    "\(proj.sprints.count) sprints • \(proj.members.count) members"
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if proj.id == currentProject.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }

                Button {
                    showCreateProject = true
                } label: {
                    Label("Create New Project", systemImage: "plus.circle")
                }
            }
            .navigationTitle("Switch Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showCreateProject) {
                CreateProjectView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ProjectTabView(
        project: .constant(Project.sample),
        viewModel: ProjectViewModel()
    )
}
