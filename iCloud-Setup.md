# iCloud / CloudKit Setup Guide

## How Storage Works

- Data is saved **locally on the device** via SwiftData (works fully offline)
- When connected, SwiftData automatically syncs to/from iCloud via CloudKit
- Changes sync across all devices signed into the same Apple ID (iPhone, iPad, etc.)
- No third-party servers (Azure, AWS, etc.) -- entirely Apple infrastructure

## Required Xcode Setup

1. Open `BalanceBookGold.xcodeproj` in Xcode
2. Select the **BalanceBookGold** target
3. Go to **Signing & Capabilities**
4. Set your **Development Team** (requires a paid Apple Developer account)
5. Verify the **iCloud** capability is listed with:
   - **CloudKit** checked
   - Container: `iCloud.com.balancebook.gold`
6. If the container doesn't exist, Xcode will prompt you to create it in your developer account

## CloudKit Dashboard

After the container is created, you can view synced data at:
https://icloud.developer.apple.com/dashboard

Select the `iCloud.com.balancebook.gold` container to inspect records.

## Key Architecture Decisions

- `@Attribute(.unique)` was removed from all SwiftData models because CloudKit does not support unique constraints
- All `@Model` stored properties have inline default values (CloudKit syncs records incrementally)
- `ModelConfiguration(cloudKitDatabase: .automatic)` handles the local + cloud sync
- Background remote notifications are enabled so CloudKit can silently push changes to other devices
- The entitlements file at `BalanceBookGold/BalanceBookGold.entitlements` configures iCloud, CloudKit, and push notifications

## Troubleshooting

- **Sync not working in Simulator?** CloudKit sync requires a signed-in iCloud account. Go to Simulator > Settings > Sign in with your Apple ID.
- **Data not appearing on another device?** Give it a moment -- CloudKit sync is eventual, not instant. Pull-to-refresh or relaunch the app.
- **Entitlements error on build?** Make sure your provisioning profile includes the iCloud capability. Xcode's automatic signing usually handles this.
- **Container not found?** Go to Xcode > Signing & Capabilities > iCloud and click the "+" to register the container with your developer account.
