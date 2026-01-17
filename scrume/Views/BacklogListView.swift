//
//  BacklogListView.swift
//  scrume
//
//  Created by NEIHT on 17/1/26.
//

import SwiftUI

/// Màn hình xem toàn bộ Product Backlog
struct BacklogListView: View {
    @Binding var project: Project
    @ObservedObject var viewModel: ProjectViewModel

    @State private var showAddStory = false
    @State private var sortBy: SortOption = .priority
    @State private var filterPriority: Priority?
    @State private var searchText = ""

    enum SortOption: String, CaseIterable {
        case priority = "Priority"
        case points = "Points"
        case date = "Date"
    }

    var body: some View {
        List {
            if project.backlog.isEmpty {
                ContentUnavailableView(
                    "Empty Backlog",
                    systemImage: "doc.text.below.ecg",
                    description: Text("Add User Story to get started")
                )
            } else if filteredBacklog.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                // Stats header
                Section {
                    HStack(spacing: 20) {
                        VStack {
                            Text("\(filteredBacklog.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Stories")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)

                        VStack {
                            Text("\(totalPoints)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.blue)
                            Text("Points")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)

                        VStack {
                            Text(avgPoints)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.orange)
                            Text("Avg")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 8)
                }

                // Stories list
                Section("Stories") {
                    ForEach(filteredBacklog.indices, id: \.self) { index in
                        let story = filteredBacklog[index]
                        NavigationLink {
                            UserStoryDetailView(
                                story: bindingForStory(story),
                                project: $project,
                                viewModel: viewModel
                            )
                        } label: {
                            EnhancedStoryRowView(story: story, project: project)
                        }
                    }
                    .onDelete(perform: deleteStory)
                    .onMove(perform: moveStory)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 80)
        }
        .searchable(text: $searchText, prompt: "Search stories...")
        .navigationTitle("Product Backlog")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddStory = true
                } label: {
                    Label("New Story", systemImage: "plus.circle.fill")
                }
            }

            ToolbarItem(placement: .secondaryAction) {
                Menu {
                    // Sort options
                    Menu("Sort by") {
                        Picker("Sort", selection: $sortBy) {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    }

                    Divider()

                    // Filter options
                    Menu("Filter by Priority") {
                        Button("All") {
                            filterPriority = nil
                        }
                        Divider()
                        ForEach(Priority.allCases) { priority in
                            Button {
                                filterPriority = priority
                            } label: {
                                Label(priority.name, systemImage: priority.icon)
                            }
                        }
                    }
                } label: {
                    Label("Options", systemImage: "line.3.horizontal.decrease.circle")
                }
            }

            ToolbarItem(placement: .secondaryAction) {
                EditButton()
            }
        }
        .sheet(isPresented: $showAddStory) {
            AddUserStoryView(project: $project, viewModel: viewModel)
        }
    }

    // MARK: - Computed Properties

    private var filteredBacklog: [UserStory] {
        var result = project.backlog

        // Filter by priority
        if let priority = filterPriority {
            result = result.filter { $0.priority == priority }
        }

        // Filter by search
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText)
                    || $0.description.localizedCaseInsensitiveContains(searchText)
                    || $0.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }

        // Sort
        switch sortBy {
        case .priority:
            result.sort { $0.priority > $1.priority }
        case .points:
            result.sort { $0.storyPoints > $1.storyPoints }
        case .date:
            result.sort { $0.createdAt > $1.createdAt }
        }

        return result
    }

    private var totalPoints: Int {
        filteredBacklog.reduce(0) { $0 + $1.storyPoints }
    }

    private var avgPoints: String {
        guard !filteredBacklog.isEmpty else { return "0" }
        let avg = Double(totalPoints) / Double(filteredBacklog.count)
        return String(format: "%.1f", avg)
    }

    private func bindingForStory(_ story: UserStory) -> Binding<UserStory> {
        Binding(
            get: {
                project.backlog.first { $0.id == story.id } ?? story
            },
            set: { newValue in
                if let index = project.backlog.firstIndex(where: { $0.id == story.id }) {
                    project.backlog[index] = newValue
                }
            }
        )
    }

    // MARK: - Actions

    private func deleteStory(at offsets: IndexSet) {
        let storiesToDelete = offsets.map { filteredBacklog[$0] }
        for story in storiesToDelete {
            if let index = project.backlog.firstIndex(where: { $0.id == story.id }) {
                project.backlog.remove(at: index)
            }
        }
        viewModel.updateProject(project)
    }

    private func moveStory(from source: IndexSet, to destination: Int) {
        // Only allow reorder when not filtered/searched
        guard filterPriority == nil && searchText.isEmpty && sortBy == .priority else { return }
        project.backlog.move(fromOffsets: source, toOffset: destination)
        viewModel.updateProject(project)
    }
}

// MARK: - Enhanced Story Row View

struct EnhancedStoryRowView: View {
    let story: UserStory
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                // Priority indicator
                Circle()
                    .fill(story.priority.color)
                    .frame(width: 10, height: 10)

                Text(story.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Spacer()

                // Story points badge
                Text("\(story.storyPoints)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: 26, height: 26)
                    .background(Color.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(Circle())
            }

            // Description preview
            if !story.description.isEmpty {
                Text(story.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            HStack(spacing: 12) {
                // Status
                Label(story.status.rawValue, systemImage: story.status.icon)
                    .font(.caption2)
                    .foregroundStyle(story.status.color)

                // Assignees
                if !story.assigneeIds.isEmpty {
                    AssigneesAvatarStack(
                        assigneeIds: story.assigneeIds,
                        members: project.members,
                        size: 14
                    )
                }

                // Acceptance criteria progress
                if !story.acceptanceCriteria.isEmpty {
                    HStack(spacing: 2) {
                        Image(systemName: "checklist")
                        Text("\(story.completedCriteriaCount)/\(story.acceptanceCriteria.count)")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                // Tags (first 2)
                if !story.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(story.tags.prefix(2), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundStyle(.blue)
                                .cornerRadius(3)
                        }
                        if story.tags.count > 2 {
                            Text("+\(story.tags.count - 2)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add User Story View

struct AddUserStoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var project: Project
    @ObservedObject var viewModel: ProjectViewModel

    @State private var title = ""
    @State private var description = ""
    @State private var priority: Priority = .medium
    @State private var storyPoints = 3
    @State private var tags: [String] = []
    @State private var newTag = ""

    private let suggestedTags = [
        "UI", "API", "Bug", "Feature", "Refactor", "Testing", "UX", "Core",
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("User Story") {
                    TextField("Title", text: $title)

                    TextField(
                        "Description (As a..., I want..., so that...)", text: $description,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                }

                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(Priority.allCases) { p in
                            Label(p.name, systemImage: p.icon)
                                .foregroundStyle(p.color)
                                .tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Story Points") {
                    Picker("Points", selection: $storyPoints) {
                        ForEach(UserStory.validPoints, id: \.self) { point in
                            Text("\(point)").tag(point)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Tags") {
                    // Selected tags
                    if !tags.isEmpty {
                        FlowLayout(spacing: 6) {
                            ForEach(tags, id: \.self) { tag in
                                HStack(spacing: 4) {
                                    Text(tag)
                                    Button {
                                        tags.removeAll { $0 == tag }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption2)
                                    }
                                }
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundStyle(.blue)
                                .cornerRadius(4)
                            }
                        }
                    }

                    // Suggested tags
                    FlowLayout(spacing: 6) {
                        ForEach(suggestedTags.filter { !tags.contains($0) }, id: \.self) { tag in
                            Button {
                                tags.append(tag)
                            } label: {
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.1))
                                    .foregroundStyle(.secondary)
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Custom tag input
                    HStack {
                        TextField("Custom tag", text: $newTag)
                            .textInputAutocapitalization(.never)

                        Button {
                            let tag = newTag.trimmingCharacters(in: .whitespaces)
                            if !tag.isEmpty && !tags.contains(tag) {
                                tags.append(tag)
                                newTag = ""
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .navigationTitle("Add User Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addStory()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func addStory() {
        let story = UserStory(
            title: title.trimmingCharacters(in: .whitespaces),
            description: description,
            priority: priority,
            storyPoints: storyPoints,
            tags: tags
        )

        project.backlog.append(story)
        viewModel.updateProject(project)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BacklogListView(
            project: .constant(Project.sample),
            viewModel: ProjectViewModel()
        )
    }
}
