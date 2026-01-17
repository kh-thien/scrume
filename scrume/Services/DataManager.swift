//
//  DataManager.swift
//  scrume
//
//  Created by NEIHT on 17/1/26.
//

import CryptoKit
import Foundation
import Security

/// DataManager - Manages local data storage
/// Uses File JSON + AES-256-GCM encryption
/// Key is stored securely in Keychain
final class DataManager {
    static let shared = DataManager()

    private let fileName = "scrume_data.encrypted"
    private let keychainKey = "com.scrume.encryptionKey"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // Legacy UserDefaults key for migration
    private let legacyUserDefaultsKey = "scrume_projects"

    private init() {
        // Migrate from UserDefaults if needed
        migrateFromUserDefaults()
    }

    // MARK: - File URL

    private var fileURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[
            0]
        return documentsPath.appendingPathComponent(fileName)
    }

    // MARK: - Encryption Key Management (Keychain)

    private func getOrCreateEncryptionKey() -> SymmetricKey {
        // Try to load existing key from Keychain
        if let existingKeyData = loadKeyFromKeychain() {
            return SymmetricKey(data: existingKeyData)
        }

        // Generate new key and save to Keychain
        let newKey = SymmetricKey(size: .bits256)
        saveKeyToKeychain(newKey)
        return newKey
    }

    private func loadKeyFromKeychain() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return data
    }

    private func saveKeyToKeychain(_ key: SymmetricKey) {
        let keyData = key.withUnsafeBytes { Data($0) }

        // Delete existing key if any
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new key
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        if status != errSecSuccess {
            print("❌ Failed to save encryption key to Keychain: \(status)")
        }
    }

    // MARK: - Encryption/Decryption

    private func encrypt(_ data: Data) throws -> Data {
        let key = getOrCreateEncryptionKey()
        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let combined = sealedBox.combined else {
            throw EncryptionError.encryptionFailed
        }
        return combined
    }

    private func decrypt(_ data: Data) throws -> Data {
        let key = getOrCreateEncryptionKey()
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }

    // MARK: - Projects CRUD

    func saveProjects(_ projects: [Project]) {
        do {
            let jsonData = try encoder.encode(projects)
            let encryptedData = try encrypt(jsonData)
            try encryptedData.write(to: fileURL, options: [.atomic, .completeFileProtection])
            print("✅ Saved \(projects.count) projects (encrypted)")
        } catch {
            print("❌ Error saving projects: \(error)")
        }
    }

    func loadProjects() -> [Project] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        do {
            let encryptedData = try Data(contentsOf: fileURL)
            let jsonData = try decrypt(encryptedData)
            let projects = try decoder.decode([Project].self, from: jsonData)
            print("✅ Loaded \(projects.count) projects (decrypted)")
            return projects
        } catch {
            print("❌ Error loading projects: \(error)")
            return []
        }
    }

    func addProject(_ project: Project) {
        var projects = loadProjects()
        projects.append(project)
        saveProjects(projects)
    }

    func updateProject(_ project: Project) {
        var projects = loadProjects()
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = project
            saveProjects(projects)
        }
    }

    func deleteProject(id: UUID) {
        var projects = loadProjects()
        projects.removeAll { $0.id == id }
        saveProjects(projects)
    }

    // MARK: - Utilities

    func clearAllData() {
        try? FileManager.default.removeItem(at: fileURL)
        print("🗑️ All data cleared")
    }

    func loadSampleData() {
        saveProjects(Project.samples)
    }

    // MARK: - Export/Import (Unencrypted JSON for backup)

    func exportData() -> Data? {
        let projects = loadProjects()
        do {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(projects)
            encoder.outputFormatting = []
            return data
        } catch {
            print("❌ Export error: \(error)")
            return nil
        }
    }

    func importData(_ data: Data) -> Bool {
        do {
            let projects = try decoder.decode([Project].self, from: data)
            saveProjects(projects)
            print("✅ Imported \(projects.count) projects")
            return true
        } catch {
            print("❌ Import error: \(error)")
            return false
        }
    }

    // MARK: - Migration from UserDefaults

    private func migrateFromUserDefaults() {
        let defaults = UserDefaults.standard

        // Check if legacy data exists
        guard let legacyData = defaults.data(forKey: legacyUserDefaultsKey) else {
            return
        }

        // Check if we already have encrypted data
        if FileManager.default.fileExists(atPath: fileURL.path) {
            // Already migrated, just clean up UserDefaults
            defaults.removeObject(forKey: legacyUserDefaultsKey)
            print("🔄 Cleaned up legacy UserDefaults data")
            return
        }

        // Migrate data
        do {
            let projects = try decoder.decode([Project].self, from: legacyData)
            saveProjects(projects)
            defaults.removeObject(forKey: legacyUserDefaultsKey)
            print("✅ Migrated \(projects.count) projects from UserDefaults to encrypted storage")
        } catch {
            print("❌ Migration error: \(error)")
        }
    }

    // MARK: - Storage Info

    var storageInfo: (fileSize: Int64, location: String) {
        let location = fileURL.path
        var fileSize: Int64 = 0

        if let attributes = try? FileManager.default.attributesOfItem(atPath: location) {
            fileSize = attributes[.size] as? Int64 ?? 0
        }

        return (fileSize, location)
    }
}

// MARK: - Errors

enum EncryptionError: Error {
    case encryptionFailed
    case decryptionFailed
}
