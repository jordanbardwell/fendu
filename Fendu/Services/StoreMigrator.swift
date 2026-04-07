import Foundation

enum StoreMigrator {

    private static let migrationKey = "hasMigratedToAppGroup"

    static func migrateIfNeeded() {
        let sharedDefaults = UserDefaults(suiteName: SharedContainer.appGroupID)
        guard sharedDefaults?.bool(forKey: migrationKey) != true else { return }

        let fileManager = FileManager.default
        let destination = SharedContainer.storeURL

        // If the destination already exists (e.g. fresh install that somehow wrote there), skip
        guard !fileManager.fileExists(atPath: destination.path) else {
            sharedDefaults?.set(true, forKey: migrationKey)
            return
        }

        // Find the old default SwiftData store
        // SwiftData stores with a named ModelConfiguration go to:
        // ~/Library/Application Support/default.store
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return
        }

        let oldStore = appSupport.appendingPathComponent("default.store")
        guard fileManager.fileExists(atPath: oldStore.path) else {
            // No old store — fresh install, nothing to migrate
            sharedDefaults?.set(true, forKey: migrationKey)
            return
        }

        // Ensure destination directory exists
        let destDir = destination.deletingLastPathComponent()
        try? fileManager.createDirectory(at: destDir, withIntermediateDirectories: true)

        // Copy all three SQLite files (.store, .store-shm, .store-wal)
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
                    print("[StoreMigrator] Copied \(src.lastPathComponent) → \(dst.lastPathComponent)")
                } catch {
                    print("[StoreMigrator] Failed to copy \(src.lastPathComponent): \(error)")
                    allCopied = false
                }
            }
        }

        if allCopied {
            sharedDefaults?.set(true, forKey: migrationKey)
            print("[StoreMigrator] Migration complete")
        }
    }
}
