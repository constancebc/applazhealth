# Applaz — Goals Delivered

Native iOS app, version 1.0.14 (8). Current health and fitness design snapshot for `constancebc/applazhealth`.

## Build locally

1. Restore the existing production `Notes/GoogleService-Info.plist` locally. It is deliberately excluded from Git. Keep Firebase project `applaz-32772`, bundle identifier `com.applaz`, existing database paths, storage and account relationships.
2. Run `pod install` using the committed lockfile, then open `Notes.xcworkspace` and choose the Notes scheme. Swift Package Manager uses the revision in Package.resolved.
3. Supply signing credentials locally for a device or distribution build.

```sh
xcodebuild -workspace Notes.xcworkspace -scheme Notes -configuration Debug \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO ARCHS=arm64 EXCLUDED_ARCHS= build
```

Generated dependencies, credentials, personal Xcode state and simulator data are excluded. The bundled SQLite seed is empty; user records are not included. This source upload does not migrate users or deploy Firebase services.

## Current features and design

Health templates cover goals, daily wellness, workouts, food diaries and fitness training alongside regular notebooks. The app includes recurring checklists, notes, reviewed meal estimates and daily tallies, notebook-scoped AI, saved chats, recorded-data charts, daily/weekly/monthly insights and social note actions. Creative-project templates are excluded.

The template creator uses labeled rows and a compact anchored list; routine notes retain the Add Note form while workouts keep their dedicated layout. The final design uses compact original navigation bars, no separate Profile top bar, black primary text, navy accents and soft pastel surfaces. The original logo shape is retained, with black bars in the app icon. The notebook overview combines consistency, trend, Find my patterns and its inline composer. AI options retains chat history, new-chat and privacy actions.

## Validation and activation

The final Debug simulator build succeeded. Targeted design checks passed overview/composer clearance above the bottom menu, keyboard interaction, recorded-value disclosure and saved-chart navigation retaining Monthly selection. Preview fixtures use fictional offline records and are not compiled into production source.

Apple subscriptions, the OpenAI secret and deployment of the new wellness Firebase backend are still activation requirements. The configured wellnessStatus endpoint returned HTTP 404 during the November 25 readiness check. This does not test existing Firebase authentication, photos or social data. Live payments, AI responses, private cross-device sync and real-account uploads require live validation. See [activation and usage policy](docs/Applaz-Plus-activation.md).

The weekly credit policy is implemented in server source and covered by local policy tests; source publication alone does not enable live enforcement. Existing account and photo operations have not been claimed live-verified by these offline design checks.

## App Store artwork

Use [AppStoreAssets/Health-Refresh](AppStoreAssets/Health-Refresh) and its UPLOAD.txt. Matching six-image sets cover large iPhone, medium iPhone and 13-inch iPad upload slots. PNGs are opaque RGB at validated Apple-accepted dimensions. iPad artwork uses native tablet captures. Overview sheets are for review only. Older asset folders are historical.
