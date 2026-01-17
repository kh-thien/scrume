//
//  BoardTabView.swift
//  scrume
//
//  Created by NEIHT on 17/1/26.
//

import SwiftUI

/// Board Tab - Scrum Board wrapper
struct BoardTabView: View {
    @Binding var project: Project
    @ObservedObject var viewModel: ProjectViewModel

    var body: some View {
        NavigationStack {
            if let activeSprint = project.activeSprint,
                let index = project.sprints.firstIndex(where: { $0.id == activeSprint.id })
            {
                ScrumBoardView(
                    sprint: bindingForSprint(at: index),
                    project: $project,
                    viewModel: viewModel
                )
            } else {
                NoSprintView(project: $project, viewModel: viewModel)
            }
        }
    }

    private func bindingForSprint(at index: Int) -> Binding<Sprint> {
        Binding(
            get: { project.sprints[index] },
            set: { project.sprints[index] = $0 }
        )
    }
}

// MARK: - No Sprint View

struct NoSprintView: View {
    @Binding var project: Project
    @ObservedObject var viewModel: ProjectViewModel
    @State private var showCreateSprint = false
    @State private var showSprintList = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "rectangle.split.3x1")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Active Sprint")
                .font(.title2)
                .fontWeight(.bold)

            Text("Start a sprint to use the Scrum Board")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                Button {
                    showCreateSprint = true
                } label: {
                    Label("Create New Sprint", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                if !project.sprints.isEmpty {
                    Button {
                        showSprintList = true
                    } label: {
                        Label("View All Sprints", systemImage: "list.bullet")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .frame(maxWidth: 280)
        }
        .navigationTitle("Scrum Board")
        .sheet(isPresented: $showCreateSprint) {
            CreateSprintView(project: $project, viewModel: viewModel)
        }
        .sheet(isPresented: $showSprintList) {
            NavigationStack {
                SprintListView(project: $project, viewModel: viewModel)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    BoardTabView(
        project: .constant(Project.sample),
        viewModel: ProjectViewModel()
    )
}
