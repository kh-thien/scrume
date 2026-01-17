//
//  ScrumBoardView.swift
//  scrume
//
//  Created by NEIHT on 17/1/26.
//

import SwiftUI

/// Scrum Board - iOS-optimized với Tab-based navigation
struct ScrumBoardView: View {
    @Binding var sprint: Sprint
    @Binding var project: Project
    @ObservedObject var viewModel: ProjectViewModel

    @State private var showStoryDetail: UserStory?
    @State private var showAddStories = false

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Progress Summary Bar
            SprintProgressBar(sprint: sprint)

            // MARK: - Three Column Board
            HStack(spacing: 8) {
                // Todo Column
                BoardColumn(
                    status: .todo,
                    stories: sprint.todoStories,
                    sprint: $sprint,
                    project: $project,
                    viewModel: viewModel,
                    showStoryDetail: $showStoryDetail
                )

                // In Progress Column
                BoardColumn(
                    status: .inProgress,
                    stories: sprint.inProgressStories,
                    sprint: $sprint,
                    project: $project,
                    viewModel: viewModel,
                    showStoryDetail: $showStoryDetail
                )

                // Done Column
                BoardColumn(
                    status: .done,
                    stories: sprint.doneStories,
                    sprint: $sprint,
                    project: $project,
                    viewModel: viewModel,
                    showStoryDetail: $showStoryDetail
                )
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 90)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Scrum Board")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(sprint.name)
                    .font(.headline)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddStories = true
                } label: {
                    Label("Add from Backlog", systemImage: "arrow.right.doc.on.clipboard")
                        .labelStyle(.iconOnly)
                }
                .accessibilityLabel("Add stories from backlog")
            }
        }
        .sheet(item: $showStoryDetail) { story in
            NavigationStack {
                BoardStoryDetailView(
                    story: story,
                    sprint: $sprint,
                    project: $project,
                    viewModel: viewModel
                )
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showAddStories) {
            AddStoriesToSprintView(
                sprint: $sprint,
                project: $project,
                viewModel: viewModel
            )
        }
    }
}

// MARK: - Board Column

struct BoardColumn: View {
    let status: StoryStatus
    let stories: [UserStory]
    @Binding var sprint: Sprint
    @Binding var project: Project
    @ObservedObject var viewModel: ProjectViewModel
    @Binding var showStoryDetail: UserStory?

    var body: some View {
        VStack(spacing: 0) {
            // Column Header
            HStack {
                Image(systemName: status.icon)
                    .font(.caption)
                    .foregroundStyle(status.color)
                
                Text(status.shortName)
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(stories.count)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(status.color.opacity(0.2)))
                    .foregroundStyle(status.color)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .cornerRadius(8, corners: [.topLeft, .topRight])

            // Stories List
            ScrollView {
                if stories.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: status.emptyIcon)
                            .font(.title2)
                            .foregroundStyle(status.color.opacity(0.4))
                        Text("No items")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(stories) { story in
                            CompactStoryCard(
                                story: story,
                                status: status,
                                project: project,
                                onTap: { showStoryDetail = story },
                                onMoveLeft: { moveStory(story, direction: .left) },
                                onMoveRight: { moveStory(story, direction: .right) }
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                }
            }
            .background(Color(.systemGray6))
            .cornerRadius(8, corners: [.bottomLeft, .bottomRight])
        }
        .frame(maxWidth: .infinity)
    }

    enum MoveDirection {
        case left, right
    }

    private func moveStory(_ story: UserStory, direction: MoveDirection) {
        guard let index = sprint.stories.firstIndex(where: { $0.id == story.id }) else { return }

        let newStatus: StoryStatus? = {
            switch (status, direction) {
            case (.todo, .right): return .inProgress
            case (.inProgress, .left): return .todo
            case (.inProgress, .right): return .done
            case (.done, .left): return .inProgress
            default: return nil
            }
        }()

        guard let newStatus = newStatus else { return }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            sprint.stories[index].status = newStatus
            sprint.stories[index].updatedAt = Date()

            if let sprintIndex = project.sprints.firstIndex(where: { $0.id == sprint.id }) {
                project.sprints[sprintIndex] = sprint
            }
            viewModel.updateProject(project)
        }

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Compact Story Card

struct CompactStoryCard: View {
    let story: UserStory
    let status: StoryStatus
    let project: Project
    let onTap: () -> Void
    let onMoveLeft: () -> Void
    let onMoveRight: () -> Void

    @State private var offset: CGFloat = 0
    @State private var showLeftAction = false
    @State private var showRightAction = false

    private let swipeThreshold: CGFloat = 50

    var body: some View {
        ZStack {
            // Background actions
            HStack {
                if canMoveLeft {
                    Image(systemName: "arrow.left")
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(RoundedRectangle(cornerRadius: 10).fill(status == .done ? Color.blue : Color.gray))
                        .opacity(showLeftAction ? 1 : 0.6)
                }
                
                if canMoveRight {
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(RoundedRectangle(cornerRadius: 10).fill(status == .todo ? Color.blue : Color.green))
                        .opacity(showRightAction ? 1 : 0.6)
                }
            }

            // Card content
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(story.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)

                // Bottom row
                HStack {
                    // Priority
                    Circle()
                        .fill(story.priority.color)
                        .frame(width: 6, height: 6)

                    // Points
                    if story.storyPoints > 0 {
                        Text("\(story.storyPoints)pt")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Assignees
                    if !story.assigneeIds.isEmpty {
                        AssigneesAvatarStack(
                            assigneeIds: story.assigneeIds,
                            members: project.members,
                            size: 18
                        )
                    }
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let translation = value.translation.width

                        if translation > 0 && !canMoveLeft {
                            offset = translation * 0.2
                        } else if translation < 0 && !canMoveRight {
                            offset = translation * 0.2
                        } else {
                            offset = translation * 0.6
                        }

                        showLeftAction = translation > swipeThreshold && canMoveLeft
                        showRightAction = translation < -swipeThreshold && canMoveRight
                    }
                    .onEnded { _ in
                        if showLeftAction {
                            onMoveLeft()
                        } else if showRightAction {
                            onMoveRight()
                        }

                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            offset = 0
                            showLeftAction = false
                            showRightAction = false
                        }
                    }
            )
            .onTapGesture(perform: onTap)
        }
    }

    private var canMoveLeft: Bool {
        status != .todo
    }

    private var canMoveRight: Bool {
        status != .done
    }
}

// MARK: - Sprint Progress Bar

struct SprintProgressBar: View {
    let sprint: Sprint

    var body: some View {
        VStack(spacing: 8) {
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))

                    // Done (green)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.green)
                        .frame(width: geo.size.width * doneRatio)

                    // In Progress (blue) overlay on done
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue)
                        .frame(width: geo.size.width * (doneRatio + inProgressRatio))
                        .mask(alignment: .leading) {
                            Rectangle()
                                .frame(width: geo.size.width * inProgressRatio)
                                .offset(x: geo.size.width * doneRatio)
                        }
                }
            }
            .frame(height: 8)

            // Stats
            HStack {
                StatLabel(value: sprint.todoStories.count, label: "To Do", color: .secondary)
                Spacer()
                StatLabel(value: sprint.inProgressStories.count, label: "In Progress", color: .blue)
                Spacer()
                StatLabel(value: sprint.doneStories.count, label: "Done", color: .green)
                Spacer()

                // Points
                HStack(spacing: 4) {
                    Text("\(sprint.completedStoryPoints)")
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                    Text("/")
                        .foregroundStyle(.secondary)
                    Text("\(sprint.totalStoryPoints)")
                        .foregroundStyle(.secondary)
                    Text("pts")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    private var totalStories: Int {
        sprint.stories.count
    }

    private var doneRatio: CGFloat {
        guard totalStories > 0 else { return 0 }
        return CGFloat(sprint.doneStories.count) / CGFloat(totalStories)
    }

    private var inProgressRatio: CGFloat {
        guard totalStories > 0 else { return 0 }
        return CGFloat(sprint.inProgressStories.count) / CGFloat(totalStories)
    }
}

struct StatLabel: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.headline)
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Status Tab Bar

struct StatusTabBar: View {
    @Binding var selectedStatus: StoryStatus
    let todoCount: Int
    let inProgressCount: Int
    let doneCount: Int

    var body: some View {
        HStack(spacing: 0) {
            StatusTab(
                status: .todo,
                count: todoCount,
                isSelected: selectedStatus == .todo
            ) {
                selectedStatus = .todo
            }

            StatusTab(
                status: .inProgress,
                count: inProgressCount,
                isSelected: selectedStatus == .inProgress
            ) {
                selectedStatus = .inProgress
            }

            StatusTab(
                status: .done,
                count: doneCount,
                isSelected: selectedStatus == .done
            ) {
                selectedStatus = .done
            }
        }
        .background(Color(.systemBackground))
    }
}

struct StatusTab: View {
    let status: StoryStatus
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: status.icon)
                        .font(.subheadline)

                    Text(status.shortName)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)

                    Text("\(count)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? status.color.opacity(0.2) : Color(.systemGray5))
                        )
                        .foregroundStyle(isSelected ? status.color : .secondary)
                }

                // Indicator
                Rectangle()
                    .fill(isSelected ? status.color : .clear)
                    .frame(height: 3)
            }
            .foregroundStyle(isSelected ? status.color : .secondary)
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(.plain)
    }
}

// MARK: - Board Column Content

struct BoardColumnContent: View {
    let status: StoryStatus
    let stories: [UserStory]
    @Binding var sprint: Sprint
    @Binding var project: Project
    @ObservedObject var viewModel: ProjectViewModel
    @Binding var showStoryDetail: UserStory?

    var body: some View {
        ScrollView {
            if stories.isEmpty {
                EmptyColumnView(status: status)
                    .padding(.top, 60)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(stories) { story in
                        SwipeableStoryCard(
                            story: story,
                            status: status,
                            project: project,
                            onTap: { showStoryDetail = story },
                            onMoveLeft: { moveStory(story, direction: .left) },
                            onMoveRight: { moveStory(story, direction: .right) }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
    }

    enum MoveDirection {
        case left, right
    }

    private func moveStory(_ story: UserStory, direction: MoveDirection) {
        guard let index = sprint.stories.firstIndex(where: { $0.id == story.id }) else { return }

        let newStatus: StoryStatus? = {
            switch (status, direction) {
            case (.todo, .right): return .inProgress
            case (.inProgress, .left): return .todo
            case (.inProgress, .right): return .done
            case (.done, .left): return .inProgress
            default: return nil
            }
        }()

        guard let newStatus = newStatus else { return }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            sprint.stories[index].status = newStatus
            sprint.stories[index].updatedAt = Date()

            if let sprintIndex = project.sprints.firstIndex(where: { $0.id == sprint.id }) {
                project.sprints[sprintIndex] = sprint
            }
            viewModel.updateProject(project)
        }

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
}

// MARK: - Empty Column View

struct EmptyColumnView: View {
    let status: StoryStatus

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: status.emptyIcon)
                .font(.system(size: 50))
                .foregroundStyle(status.color.opacity(0.5))

            Text(status.emptyMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}

// MARK: - Swipeable Story Card

struct SwipeableStoryCard: View {
    let story: UserStory
    let status: StoryStatus
    let project: Project
    let onTap: () -> Void
    let onMoveLeft: () -> Void
    let onMoveRight: () -> Void

    @State private var offset: CGFloat = 0
    @State private var showLeftAction = false
    @State private var showRightAction = false

    private let swipeThreshold: CGFloat = 80

    var body: some View {
        ZStack {
            // Background actions
            HStack {
                // Left action (move back)
                if canMoveLeft {
                    leftActionBackground
                }

                Spacer()

                // Right action (move forward)
                if canMoveRight {
                    rightActionBackground
                }
            }

            // Card
            StoryCardView(story: story, project: project)
                .offset(x: offset)
                .gesture(
                    DragGesture(minimumDistance: 20, coordinateSpace: .local)
                        .onChanged { value in
                            let translation = value.translation.width
                            let verticalMovement = abs(value.translation.height)
                            
                            // Only handle horizontal swipes (ignore vertical scrolling)
                            guard abs(translation) > verticalMovement else {
                                return
                            }

                            // Limit swipe based on available actions
                            if translation > 0 && !canMoveLeft {
                                offset = translation * 0.2
                            } else if translation < 0 && !canMoveRight {
                                offset = translation * 0.2
                            } else {
                                offset = translation * 0.6
                            }

                            showLeftAction = translation > swipeThreshold && canMoveLeft
                            showRightAction = translation < -swipeThreshold && canMoveRight
                        }
                        .onEnded { value in
                            if showLeftAction {
                                onMoveLeft()
                            } else if showRightAction {
                                onMoveRight()
                            }

                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                offset = 0
                                showLeftAction = false
                                showRightAction = false
                            }
                        }
                )
                .onTapGesture(perform: onTap)
        }
    }

    private var canMoveLeft: Bool {
        status != .todo
    }

    private var canMoveRight: Bool {
        status != .done
    }

    private var leftActionBackground: some View {
        HStack {
            VStack {
                Image(systemName: "arrow.left.circle.fill")
                    .font(.title2)
                Text(status == .done ? "In Progress" : "To Do")
                    .font(.caption2)
            }
            .foregroundStyle(.white)
            .padding(.leading, 20)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(status == .done ? Color.blue : Color.gray)
        )
        .opacity(showLeftAction ? 1 : 0.6)
    }

    private var rightActionBackground: some View {
        HStack {
            Spacer()

            VStack {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                Text(status == .todo ? "In Progress" : "Done")
                    .font(.caption2)
            }
            .foregroundStyle(.white)
            .padding(.trailing, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(status == .todo ? Color.blue : Color.green)
        )
        .opacity(showRightAction ? 1 : 0.6)
    }
}

// MARK: - Story Card View

struct StoryCardView: View {
    let story: UserStory
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top row: Priority badge + Story points
            HStack {
                // Priority
                HStack(spacing: 4) {
                    Image(systemName: story.priority.icon)
                    Text(story.priority.name)
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(story.priority.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(story.priority.color.opacity(0.12))
                .cornerRadius(6)

                Spacer()

                // Story points
                Text("\(story.storyPoints) pts")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
            }

            // Title
            Text(story.title)
                .font(.body)
                .fontWeight(.medium)
                .lineLimit(2)

            // Description preview
            if !story.description.isEmpty {
                Text(story.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            // Tags
            if !story.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(story.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color(.systemGray5))
                                .cornerRadius(4)
                        }
                    }
                }
            }

            Divider()

            // Bottom row: Assignee + Checklist
            HStack {
                // Assignees
                if !story.assigneeIds.isEmpty {
                    let assignees = project.members.filter { story.assigneeIds.contains($0.id) }
                    HStack(spacing: -8) {
                        ForEach(assignees.prefix(3)) { member in
                            Circle()
                                .fill(Color(hex: member.avatarColor))
                                .frame(width: 24, height: 24)
                                .overlay {
                                    Text(member.initials)
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                                .overlay {
                                    Circle().stroke(Color(.systemBackground), lineWidth: 2)
                                }
                        }
                        if assignees.count > 3 {
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 24, height: 24)
                                .overlay {
                                    Text("+\(assignees.count - 3)")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                                .overlay {
                                    Circle().stroke(Color(.systemBackground), lineWidth: 2)
                                }
                        }
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "person.badge.plus")
                        Text("Unassigned")
                    }
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                }

                Spacer()

                // Acceptance criteria
                if !story.acceptanceCriteria.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "checklist")
                        Text("\(story.completedCriteriaCount)/\(story.acceptanceCriteria.count)")
                    }
                    .font(.caption)
                    .foregroundStyle(
                        story.completedCriteriaCount == story.acceptanceCriteria.count
                            ? .green : .secondary
                    )
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Board Story Detail

struct BoardStoryDetailView: View {
    let story: UserStory
    @Binding var sprint: Sprint
    @Binding var project: Project
    @ObservedObject var viewModel: ProjectViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var currentStory: UserStory

    init(
        story: UserStory, sprint: Binding<Sprint>, project: Binding<Project>,
        viewModel: ProjectViewModel
    ) {
        self.story = story
        self._sprint = sprint
        self._project = project
        self.viewModel = viewModel
        self._currentStory = State(initialValue: story)
    }

    var body: some View {
        List {
            // Status Section - Horizontal buttons
            Section {
                HStack(spacing: 8) {
                    ForEach(StoryStatus.boardStatuses) { status in
                        Button {
                            updateStatus(to: status)
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: status.icon)
                                    .font(.title3)
                                Text(status.shortName)
                                    .font(.caption2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        currentStory.status == status
                                            ? status.color.opacity(0.2)
                                            : Color(.systemGray6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        currentStory.status == status
                                            ? status.color
                                            : .clear, lineWidth: 2)
                            )
                        }
                        .foregroundStyle(currentStory.status == status ? status.color : .secondary)
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
            }

            // Info Section
            Section("Details") {
                LabeledContent("Priority") {
                    Label(currentStory.priority.name, systemImage: currentStory.priority.icon)
                        .foregroundStyle(currentStory.priority.color)
                }

                LabeledContent("Story Points") {
                    Text("\(currentStory.storyPoints)")
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                }

                if !currentStory.description.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(currentStory.description)
                            .font(.subheadline)
                    }
                }
            }

            // Assignee Section
            Section("Assignees") {
                // Current assignees
                let assignees = project.members.filter { currentStory.assigneeIds.contains($0.id) }
                ForEach(assignees) { member in
                    HStack {
                        TeamMemberRowView(member: member)

                        Spacer()

                        Button {
                            currentStory.assigneeIds.removeAll { $0 == member.id }
                            saveChanges()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                        }
                    }
                }

                // Add more assignees
                let availableMembers = project.members.filter { !currentStory.assigneeIds.contains($0.id) }
                if !availableMembers.isEmpty {
                    Menu {
                        ForEach(availableMembers) { member in
                            Button {
                                currentStory.assigneeIds.append(member.id)
                                saveChanges()
                            } label: {
                                Label(member.name, systemImage: member.role.icon)
                            }
                        }
                    } label: {
                        Label("Add Assignee...", systemImage: "person.badge.plus")
                    }
                }
            }

            // Acceptance Criteria
            if !currentStory.acceptanceCriteria.isEmpty {
                Section {
                    ForEach($currentStory.acceptanceCriteria) { $criterion in
                        AcceptanceCriterionRow(criterion: $criterion) {
                            saveChanges()
                        }
                    }
                } header: {
                    HStack {
                        Text("Acceptance Criteria")
                        Spacer()
                        Text(
                            "\(currentStory.completedCriteriaCount)/\(currentStory.acceptanceCriteria.count)"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(currentStory.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }

    private func updateStatus(to status: StoryStatus) {
        currentStory.status = status
        saveChanges()

        // Haptic
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    private func saveChanges() {
        currentStory.updatedAt = Date()

        if let index = sprint.stories.firstIndex(where: { $0.id == currentStory.id }) {
            sprint.stories[index] = currentStory
        }

        if let sprintIndex = project.sprints.firstIndex(where: { $0.id == sprint.id }) {
            project.sprints[sprintIndex] = sprint
        }

        viewModel.updateProject(project)
    }
}

// MARK: - StoryStatus Extensions

extension StoryStatus {
    static var boardStatuses: [StoryStatus] {
        [.todo, .inProgress, .done]
    }

    var shortName: String {
        switch self {
        case .todo: return "To Do"
        case .inProgress: return "Progress"
        case .done: return "Done"
        default: return rawValue
        }
    }

    var emptyIcon: String {
        switch self {
        case .todo: return "tray"
        case .inProgress: return "figure.run"
        case .done: return "party.popper"
        default: return "questionmark"
        }
    }

    var emptyMessage: String {
        switch self {
        case .todo: return "No stories waiting.\nSwipe from In Progress to move here."
        case .inProgress: return "No stories in progress.\nSwipe right on a To Do story to start."
        case .done: return "No completed stories yet.\nSwipe right on In Progress to complete."
        default: return "Empty"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ScrumBoardView(
            sprint: .constant(Sprint.sample),
            project: .constant(Project.sample),
            viewModel: ProjectViewModel()
        )
    }
}
