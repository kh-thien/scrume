//
//  MainTabView.swift
//  scrume
//
//  Created by NEIHT on 17/1/26.
//

import SwiftUI

/// Main Tab View - Adaptive for iPhone and iPad
struct MainTabView: View {
    @ObservedObject var viewModel: ProjectViewModel
    @Binding var project: Project

    @State private var selectedTab = 0
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let tabs: [(icon: String, label: String)] = [
        ("house.fill", "Home"),
        ("rectangle.split.3x1.fill", "Board"),
        ("list.bullet.rectangle.fill", "Backlog"),
        ("chart.bar.fill", "Reports"),
        ("folder.fill", "Project"),
    ]

    private var isIPad: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        Group {
            if isIPad {
                // iPad: Use Sidebar Navigation
                NavigationSplitView {
                    iPadSidebar
                } detail: {
                    iPadDetailView
                }
            } else {
                // iPhone: Use Floating Tab Bar
                ZStack(alignment: .bottom) {
                    TabView(selection: $selectedTab) {
                        HomeTabView(
                            project: $project, viewModel: viewModel, selectedTab: $selectedTab
                        )
                        .tag(0)

                        BoardTabView(project: $project, viewModel: viewModel)
                            .tag(1)

                        BacklogTabView(project: $project, viewModel: viewModel)
                            .tag(2)

                        ReportsTabView(project: $project, viewModel: viewModel)
                            .tag(3)

                        ProjectTabView(project: $project, viewModel: viewModel)
                            .tag(4)
                    }

                    customTabBar
                }
                .onAppear {
                    UITabBar.appearance().isHidden = true
                }
            }
        }
    }

    // MARK: - iPad Sidebar
    private var iPadSidebar: some View {
        List(
            selection: Binding(
                get: { selectedTab },
                set: { newValue in
                    if let value = newValue {
                        selectedTab = value
                    }
                }
            )
        ) {
            Section("Navigation") {
                ForEach(0..<tabs.count, id: \.self) { index in
                    Label(tabs[index].label, systemImage: tabs[index].icon)
                        .tag(index)
                }
            }

            Section("Project") {
                HStack {
                    Circle()
                        .fill(Color.blue.gradient)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(String(project.name.prefix(1)))
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(project.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("\(project.sprints.count) sprints")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Scrume")
        .listStyle(.sidebar)
    }

    // MARK: - iPad Detail View
    @ViewBuilder
    private var iPadDetailView: some View {
        switch selectedTab {
        case 0:
            HomeTabView(project: $project, viewModel: viewModel, selectedTab: $selectedTab)
        case 1:
            BoardTabView(project: $project, viewModel: viewModel)
        case 2:
            BacklogTabView(project: $project, viewModel: viewModel)
        case 3:
            ReportsTabView(project: $project, viewModel: viewModel)
        case 4:
            ProjectTabView(project: $project, viewModel: viewModel)
        default:
            HomeTabView(project: $project, viewModel: viewModel, selectedTab: $selectedTab)
        }
    }

    // MARK: - Custom Tab Bar (iPhone)
    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                tabButton(index: index)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Tab Button
    private func tabButton(index: Int) -> some View {
        let isSelected = selectedTab == index

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = index
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tabs[index].icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .scaleEffect(isSelected ? 1.1 : 1.0)

                Text(tabs[index].label)
                    .font(.system(size: 10, weight: isSelected ? .medium : .regular))
            }
            .foregroundStyle(isSelected ? .blue : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    MainTabView(
        viewModel: ProjectViewModel(),
        project: .constant(Project.sample)
    )
}
