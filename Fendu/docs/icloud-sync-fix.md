# iCloud CloudKit Sync Fix

## Problem

After reinstalling the app, user data was not restored from iCloud. CloudKit sync silently failed.

## Root Cause

In v1.0.8, `SharedContainer.makeModelContainer()` was changed to provide a custom `url:` parameter to `ModelConfiguration`, placing the SQLite store in the App Group container:

```swift
// BROKEN — custom URL breaks CloudKit sync identity
let config = ModelConfiguration(
    "BalanceBookGold",
    schema: schema,
    url: storeURL,               // <-- this line
    cloudKitDatabase: .automatic
)
```

When SwiftData's underlying `NSPersistentCloudKitContainer` is given a custom store URL, it uses that path as part of the CloudKit zone identity. On reinstall:

1. The App Group container is wiped (local storage, not iCloud)
2. CloudKit has records keyed to the old store path
3. The new store at the same App Group URL doesn't match CloudKit's internal mapping
4. CloudKit treats it as a different database and doesn't rehydrate

The original code (pre-v1.0.8) used no custom URL, letting SwiftData manage the path. CloudKit sync worked correctly because `NSPersistentCloudKitContainer` controls the store location and maintains consistent zone mapping.

## Fix (applied 2026-04-15)

### 1. SharedContainer.swift

Removed `url: storeURL` from `ModelConfiguration`:

```swift
// FIXED — let SwiftData/CloudKit manage the store path
let config = ModelConfiguration(
    "BalanceBookGold",
    schema: schema,
    cloudKitDatabase: .automatic
)
```

The old `storeURL` was renamed to `legacyAppGroupStoreURL` and kept only for migration.

### 2. StoreMigrator.swift

Added Phase 2 reverse migration for existing v1.0.8+ users whose data lives in the App Group container. On first launch after the update, it copies the App Group store back to `~/Library/Application Support/default.store` (SwiftData's default path). Skips if the default store already exists (CloudKit may have already synced data).

Migration flow on launch:
```
Phase 1: old default.store → App Group (legacy, for pre-v1.0.8 users)
Phase 2: App Group → default.store (new, undoes the v1.0.8 move)
```

### 3. Widget Extension Entitlements

`FenduWidgetExtension.entitlements` and `FenduWidgetExtensionDebug.entitlements` were both missing CloudKit entitlements. Without these, the widget extension could never create a CloudKit-backed `ModelContainer`. Added:

- `com.apple.developer.icloud-container-identifiers` → `iCloud.com.jordanbardwell.Fendu`
- `com.apple.developer.icloud-services` → `CloudKit`
- `com.apple.security.application-groups` → `group.com.jordanbardwell.Fendu` (was also missing from release entitlements)

## Key Lesson

Never pass a custom `url:` to `ModelConfiguration` when using `cloudKitDatabase: .automatic`. Let SwiftData choose the store location — CloudKit's sync identity depends on it. If you need to share data with a widget extension, give the extension the same CloudKit entitlements and let it create its own `ModelContainer` with the same schema and `.automatic` CloudKit database. CloudKit handles the cross-process sync.

## Files Changed

| File | Change |
|------|--------|
| `Fendu/Services/SharedContainer.swift` | Removed `url:` param from ModelConfiguration |
| `Fendu/Services/StoreMigrator.swift` | Added Phase 2 reverse migration |
| `FenduWidgetExtension.entitlements` | Added CloudKit + App Groups |
| `FenduWidgetExtensionDebug.entitlements` | Added CloudKit entitlements |
