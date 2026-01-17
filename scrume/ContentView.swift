//
//  ContentView.swift
//  scrume
//
//  Created by NEIHT on 17/1/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ProjectViewModel()
    @State private var selectedProject: Project?
    @State private var showCreateProject = false

    var body: some View {
        contentBody
            .onChange(of: viewModel.projects) { oldValue, newValue in
                syncSelectedProject(with: newValue)
            }
            .sheet(isPresented: $showCreateProject) {
                CreateProjectView(viewModel: viewModel)
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
    }

    // MARK: - Content Body

    @ViewBuilder
    private var contentBody: some View {
        if viewModel.isLoading {
            ProgressView("Loading...")
        } else if let projectIndex = selectedProjectIndex,
            projectIndex < viewModel.projects.count
        {
            MainTabView(
                viewModel: viewModel,
                project: projectBinding(at: projectIndex)
            )
            .id(viewModel.projects[projectIndex].id)
        } else if viewModel.hasProjects {
            Color.clear
                .onAppear {
                    selectedProject = viewModel.projects.first
                }
        } else {
            emptyStateView
        }
    }

    // MARK: - Helpers

    private var selectedProjectIndex: Int? {
        guard let selected = selectedProject else { return nil }
        return viewModel.projects.firstIndex(where: { $0.id == selected.id })
    }

    private func projectBinding(at index: Int) -> Binding<Project> {
        Binding(
            get: {
                guard index >= 0 && index < viewModel.projects.count else {
                    // Return a placeholder project if index is invalid
                    // This can happen during data clearing transitions
                    return Project(name: "", description: "")
                }
                return viewModel.projects[index]
            },
            set: {
                guard index >= 0 && index < viewModel.projects.count else { return }
                viewModel.projects[index] = $0
            }
        )
    }

    private func syncSelectedProject(with newProjects: [Project]) {
        if let current = selectedProject {
            if let updated = newProjects.first(where: { $0.id == current.id }) {
                selectedProject = updated
            } else {
                selectedProject = newProjects.first
            }
        } else {
            selectedProject = newProjects.first
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 70))
                    .foregroundStyle(.blue)

                Text("Welcome to Scrume!")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Create your first project to get started with Scrum management")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Button {
                    showCreateProject = true
                } label: {
                    Label("Create Project", systemImage: "plus.circle.fill")
                        .fontWeight(.semibold)
                        .frame(minWidth: 200)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top)

                // Debug button
                Button {
                    viewModel.loadSampleData()
                } label: {
                    Label("Load Sample Data", systemImage: "tray.and.arrow.down.fill")
                }
                .buttonStyle(.bordered)
            }
            .navigationTitle("Scrume")
        }
    }
}

// MARK: - Project Row (kept for future multi-project view)

struct ProjectRowView: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(project.name)
                    .font(.headline)

                Spacer()

                if let sprint = project.activeSprint {
                    Label(sprint.status.rawValue, systemImage: sprint.status.icon)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(sprint.status.color.opacity(0.2))
                        .foregroundStyle(sprint.status.color)
                        .cornerRadius(6)
                }
            }

            if !project.description.isEmpty {
                Text(project.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 16) {
                Label("\(project.members.count)", systemImage: "person.2.fill")
                Label(
                    "\(project.sprints.count) sprints", systemImage: "arrow.triangle.2.circlepath")
                Label("\(project.sprintDurationWeeks)w", systemImage: "calendar")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
