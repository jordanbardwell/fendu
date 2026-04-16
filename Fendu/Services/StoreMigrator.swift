import Foundation

enum StoreMigrator {

    private static let migrationKey = "hasMigratedToAppGroup"
    private static let reverseMigrationKey = "hasMigratedBackToDefault"

    static func migrateIfNeeded() {
        migrateFromOldDefault()
        migrateFromAppGroupToDefault()
    }

    // MARK: - Phase 1: Original → App Group (v1.0.8)
    // Kept for users who somehow still have the very old default.store
    // that was never migrated. Moves it to App Group, then Phase 2
    // picks it up on the same launch.

    private static func migrateFromOldDefault() {
        let sharedDefaults = UserDefaults(suiteName: SharedContainer.appGroupID)
        guard sharedDefaults?.bool(forKey: migrationKey) != true else { return }

        let fileManager = FileManager.default
        let destination = SharedContainer.legacyAppGroupStoreURL

        guard !fileManager.fileExists(atPath: destination.path) else {
            sharedDefaults?.set(true, forKey: migrationKey)
            return
        }

        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return
        }

        let oldStore = appSupport.appendingPathComponent("default.store")
        guard fileManager.fileExists(atPath: oldStore.path) else {
            sharedDefaults?.set(true, forKey: migrationKey)
            return
        }

        let destDir = destination.deletingLastPathComponent()
        try? fileManager.createDirectory(at: destDir, withIntermediateDirectories: true)

        let extensions = ["", "-shm", "-wal"]
        var allCopied = true
        for ext in extensions {
            let src = oldStore.deletingLastPathComponent()
                .appendingPathComponent("default.store\(ext)")
            let dst = destination.deletingLastPathComponent()
                .appendingPathComponent("BalanceBookGold.store\(ext)")

            if fileManager.fileExists(atPath: src.path) {
                do {
                    try fileManager.copyItem(at: src, to: dst)
                } catch {
                    print("[StoreMigrator] Phase 1: Failed to copy \(src.lastPathComponent): \(error)")
                    allCopied = false
                }
            }
        }

        if allCopied {
            sharedDefaults?.set(true, forKey: migrationKey)
        }
    }

    // MARK: - Phase 2: App Group → Default SwiftData location
    // v1.0.8 moved the store to the App Group container with a custom URL,
    // which broke CloudKit sync on reinstall. Move it back to the default
    // SwiftData path so CloudKit can manage it properly.

    private static func migrateFromAppGroupToDefault() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: reverseMigrationKey) else { return }

        let fileManager = FileManager.default
        let source = SharedContainer.legacyAppGroupStoreURL

        // Nothing to migrate if the App Group store doesn't exist
        guard fileManager.fileExists(atPath: source.path) else {
            defaults.set(true, forKey: reverseMigrationKey)
            return
        }

        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return
        }

        // SwiftData's default store path for a named ModelConfiguration
        let destination = appSupport.appendingPathComponent("default.store")

        // Don't overwrite if the default store already has data
        guard !fileManager.fileExists(atPath: destination.path) else {
            defaults.set(true, forKey: reverseMigrationKey)
            return
        }

        try? fileManager.createDirectory(at: appSupport, withIntermediateDirectories: true)

        let extensions = ["", "-shm", "-wal"]
        var allCopied = true
        for ext in extensions {
            let src = source.deletingLastPathComponent()
                .appendingPathComponent("BalanceBookGold.store\(ext)")
            let dst = appSupport.appendingPathComponent("default.store\(ext)")

            if fileManager.fileExists(atPath: src.path) {
                do {
                    try fileManager.copyItem(at: src, to: dst)
                } catch {
                    print("[StoreMigrator] Phase 2: Failed to copy \(src.lastPathComponent): \(error)")
                    allCopied = false
                }
            }
        }

        if allCopied {
            defaults.set(true, forKey: reverseMigrationKey)
            print("[StoreMigrator] Phase 2: Migrated App Group store back to default location")
        }
    }
}
