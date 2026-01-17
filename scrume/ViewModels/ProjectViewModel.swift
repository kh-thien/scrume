//
//  ProjectViewModel.swift
//  scrume
//
//  Created by NEIHT on 17/1/26.
//

import Foundation

/// ViewModel cho quản lý Projects
/// MVVM Pattern - View observe các @Published properties
@MainActor
class ProjectViewModel: ObservableObject {

    // MARK: - Published State

    @Published var projects: [Project] = []
    @Published var selectedProject: Project?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    // MARK: - Dependencies

    private let dataManager = DataManager.shared

    // MARK: - Init

    init() {
        loadProjects()
    }

    // MARK: - CRUD Operations

    func loadProjects() {
        isLoading = true
        projects = dataManager.loadProjects()
        isLoading = false
    }

    func createProject(name: String, description: String, sprintDuration: Int) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Tên project không được để trống"
            showError = true
            return
        }

        let project = Project(
            name: name.trimmingCharacters(in: .whitespaces),
            description: description,
            sprintDurationWeeks: sprintDuration
        )

        dataManager.addProject(project)
        loadProjects()
    }

    func updateProject(_ project: Project) {
        dataManager.updateProject(project)
        loadProjects()

        if selectedProject?.id == project.id {
            selectedProject = project
        }
    }

    func deleteProject(_ project: Project) {
        dataManager.deleteProject(id: project.id)
        loadProjects()

        if selectedProject?.id == project.id {
            selectedProject = nil
        }
    }

    func deleteProjects(at offsets: IndexSet) {
        for index in offsets {
            deleteProject(projects[index])
        }
    }

    func addProject(_ project: Project) {
        dataManager.addProject(project)
        loadProjects()
    }

    // MARK: - Computed Properties

    var hasProjects: Bool { !projects.isEmpty }
    var projectCount: Int { projects.count }

    // MARK: - Debug

    func loadSampleData() {
        dataManager.loadSampleData()
        loadProjects()
    }

    func clearAllData() {
        dataManager.clearAllData()
        loadProjects()
    }
}
