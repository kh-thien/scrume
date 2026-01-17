//
//  MainTabView.swift
//  scrume
//
//  Created by NEIHT on 17/1/26.
//

import SwiftUI

/// Main Tab View - Modern floating tab bar
struct MainTabView: View {
    @ObservedObject var viewModel: ProjectViewModel
    @Binding var project: Project

    @State private var selectedTab = 0

    private let tabs: [(icon: String, label: String)] = [
        ("house.fill", "Home"),
        ("rectangle.split.3x1.fill", "Board"),
        ("list.bullet.rectangle.fill", "Backlog"),
        ("chart.bar.fill", "Reports"),
        ("folder.fill", "Project"),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            TabView(selection: $selectedTab) {
                HomeTabView(project: $project, viewModel: viewModel, selectedTab: $selectedTab)
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

            // Custom Floating Tab Bar
            customTabBar
        }
        .onAppear {
            // Hide default tab bar
            UITabBar.appearance().isHidden = true
        }
    }

    // MARK: - Custom Tab Bar
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
