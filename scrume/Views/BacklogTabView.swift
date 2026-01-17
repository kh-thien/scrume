//
//  BacklogTabView.swift
//  scrume
//
//  Created by NEIHT on 17/1/26.
//

import SwiftUI

/// Backlog Tab - Product Backlog wrapper
struct BacklogTabView: View {
    @Binding var project: Project
    @ObservedObject var viewModel: ProjectViewModel

    var body: some View {
        NavigationStack {
            BacklogListView(project: $project, viewModel: viewModel)
        }
    }
}

// MARK: - Preview

#Preview {
    BacklogTabView(
        project: .constant(Project.sample),
        viewModel: ProjectViewModel()
    )
}
