//
//  ProjectDetailView.swift
//  scrume
//
//  Created by NEIHT on 17/1/26.
//

import SwiftUI

/// Màn hình chi tiết Project
struct ProjectDetailView: View {
    @ObservedObject var viewModel: ProjectViewModel
    @State var project: Project

    @State private var showEditProject = false
    @State private var showAddMember = false
    @State private var showAddSprint = false

    var body: some View {
        List {
            // MARK: - Project Info Section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    if !project.description.isEmpty {
                        Text(project.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 20) {
                        StatView(
                            icon: "calendar",
                            value: "\(project.sprintDurationWeeks)",
                            label: "weeks/sprint"
                        )

                        StatView(
                            icon: "person.2.fill",
                            value: "\(project.members.count)",
                            label: "members"
                        )

                        StatView(
                            icon: "doc.text.fill",
                            value: "\(project.backlog.count)",
                            label: "backlog"
                        )
                    }
                }
                .padding(.vertical, 4)
            }

            // MARK: - Team Section
            Section {
                if project.members.isEmpty {
                    Button {
                        showAddMember = true
                    } label: {
                        Label("Add first team member", systemImage: "person.badge.plus")
                    }
                } else {
                    ForEach(project.members) { member in
                        TeamMemberRowView(member: member)
                    }
                    .onDelete(perform: deleteMember)

                    Button {
                        showAddMember = true
                    } label: {
                        Label("Add member", systemImage: "plus.circle")
                    }
                }
            } header: {
                HStack {
                    Text("Team (\(project.members.count))")
                    Spacer()
                }
            }

            // MARK: - Sprints Section
            Section {
                if project.sprints.isEmpty {
                    Button {
                        showAddSprint = true
                    } label: {
                        Label("Create first Sprint", systemImage: "arrow.triangle.2.circlepath")
                    }
                } else {
                    // Show active sprint first if exists
                    if let activeSprint = project.activeSprint,
                        let index = project.sprints.firstIndex(where: { $0.id == activeSprint.id })
                    {

                        // Quick access to Scrum Board
                        NavigationLink {
                            ScrumBoardView(
                                sprint: bindingForSprint(at: index),
                                project: $project,
                                viewModel: viewModel
                            )
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.split.3x1")
                                    .font(.title2)
                                    .foregroundStyle(.blue)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Scrum Board")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text(
                                        "\(activeSprint.name) • \(activeSprint.stories.count) stories"
                                    )
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }

                        NavigationLink {
                            SprintDetailView(
                                sprint: bindingForSprint(at: index),
                                project: $project,
                                viewModel: viewModel
                            )
                        } label: {
                            ActiveSprintRowView(sprint: activeSprint)
                        }
                    }

                    // Show other sprints (up to 2)
                    ForEach(project.sprints.filter { $0.status != .active }.prefix(2)) { sprint in
                        if let index = project.sprints.firstIndex(where: { $0.id == sprint.id }) {
                            NavigationLink {
                                SprintDetailView(
                                    sprint: bindingForSprint(at: index),
                                    project: $project,
                                    viewModel: viewModel
                                )
                            } label: {
                                SprintRowView(sprint: sprint)
                            }
                        }
                    }

                    // Link to all sprints
                    NavigationLink {
                        SprintListView(project: $project, viewModel: viewModel)
                    } label: {
                        HStack {
                            Label("Xem tất cả Sprints", systemImage: "list.bullet.rectangle")
                            Spacer()
                            Text("\(project.sprints.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Sprints (\(project.sprints.count))")
            }

            // MARK: - Backlog Section
            Section {
                if project.backlog.isEmpty {
                    Button {
                        // Navigate to backlog to add stories
                    } label: {
                        Label("Add first User Story", systemImage: "doc.badge.plus")
                    }
                } else {
                    ForEach(project.backlog.prefix(3)) { story in
                        UserStoryRowView(story: story)
                    }
                }

                // Always show link to full backlog
                NavigationLink {
                    BacklogListView(project: $project, viewModel: viewModel)
                } label: {
                    HStack {
                        Label("View Product Backlog", systemImage: "list.bullet.rectangle")
                        Spacer()
                        Text("\(project.backlog.count) stories")
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                HStack {
                    Text("Product Backlog")
                    Spacer()
                    Text("\(project.totalBacklogPoints) points")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(project.name)
        .toolbar {
            // Scrum Board shortcut in toolbar
            if let activeSprint = project.activeSprint,
                let index = project.sprints.firstIndex(where: { $0.id == activeSprint.id })
            {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        ScrumBoardView(
                            sprint: bindingForSprint(at: index),
                            project: $project,
                            viewModel: viewModel
                        )
                    } label: {
                        Image(systemName: "rectangle.split.3x1")
                    }
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    showEditProject = true
                } label: {
                    Text("Edit")
                }
            }
        }
        .sheet(isPresented: $showEditProject) {
            EditProjectView(project: $project, viewModel: viewModel)
        }
        .sheet(isPresented: $showAddMember) {
            AddMemberView(project: $project, viewModel: viewModel)
        }
        .sheet(isPresented: $showAddSprint) {
            CreateSprintView(project: $project, viewModel: viewModel)
        }
    }

    // MARK: - Actions

    private func deleteMember(at offsets: IndexSet) {
        project.members.remove(atOffsets: offsets)
        viewModel.updateProject(project)
    }

    private func bindingForSprint(at index: Int) -> Binding<Sprint> {
        Binding(
            get: { project.sprints[index] },
            set: { project.sprints[index] = $0 }
        )
    }
}

// MARK: - Active Sprint Row

struct ActiveSprintRowView: View {
    let sprint: Sprint

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(sprint.name, systemImage: "play.circle.fill")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)

                Spacer()

                if let endDate = sprint.endDate {
                    let days =
                        Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
                    Text(days >= 0 ? "\(days)d" : "!")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(days >= 0 ? .blue : .red)
                }
            }

            ProgressView(value: sprint.progressPercentage, total: 100)
                .tint(.blue)

            HStack {
                Text("\(sprint.completedStoryPoints)/\(sprint.totalStoryPoints) pts")
                Spacer()
                Text("\(Int(sprint.progressPercentage))%")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Stat View

struct StatView: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Team Member Row

struct TeamMemberRowView: View {
    let member: TeamMember

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color(hex: member.avatarColor))
                    .frame(width: 40, height: 40)

                Text(member.initials)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(member.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Label(member.role.rawValue, systemImage: member.role.icon)
                    .font(.caption)
                    .foregroundStyle(member.role.color)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Sprint Row

struct SprintRowView: View {
    let sprint: Sprint

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(sprint.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Label(sprint.status.rawValue, systemImage: sprint.status.icon)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(sprint.status.color.opacity(0.2))
                    .foregroundStyle(sprint.status.color)
                    .cornerRadius(6)
            }

            if !sprint.goal.isEmpty {
                Text(sprint.goal)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            // Progress
            if sprint.status == .active {
                ProgressView(value: sprint.progressPercentage, total: 100)
                    .tint(.blue)

                HStack {
                    Text("\(sprint.completedStoryPoints)/\(sprint.totalStoryPoints) points")
                    Spacer()
                    Text("\(Int(sprint.progressPercentage))%")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - User Story Row

struct UserStoryRowView: View {
    let story: UserStory

    var body: some View {
        HStack(spacing: 12) {
            // Priority indicator
            Circle()
                .fill(story.priority.color)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(story.title)
                    .font(.subheadline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Label(story.priority.name, systemImage: story.priority.icon)
                        .font(.caption2)
                        .foregroundStyle(story.priority.color)

                    Label(story.status.rawValue, systemImage: story.status.icon)
                        .font(.caption2)
                        .foregroundStyle(story.status.color)
                }
            }

            Spacer()

            // Story points
            Text("\(story.storyPoints)")
                .font(.caption)
                .fontWeight(.bold)
                .frame(width: 24, height: 24)
                .background(Color.blue.opacity(0.1))
                .foregroundStyle(.blue)
                .clipShape(Circle())
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ProjectDetailView(
            viewModel: ProjectViewModel(),
            project: Project.sample
        )
    }
}
