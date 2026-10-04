# Private native QA plan, source prepared only

No compiler, native runtime, device boot, provider request or GUI action has been performed for this candidate. Root owns the serialized build/runtime allocation. Scheme `My Funny Valentine` and target names below come from the existing native project and historical passing receipts. Root must inspect the newly generated xctestrun and actual test enumeration before selecting tests.

## Private app contracts

- DEBUG UI launch requires `--mfv-ui-tests --mfv-test-session <canonical UUID>`. The UI test creates a fresh UUID for each method and reuses it only for that method's relaunch. Before any interaction it requires `mfv.private.ui.<UUID>` in native accessibility.
- A valid private UI process uses `UserDefaults(suiteName: "MFVPrivateQA.<UUID>")`, temporary `MFVPrivateQA-<UUID>/Store/cards.store` with `cloudKitDatabase: .none`, and `MFVPrivateQA-<UUID>/Media` for exports and legacy media helpers. Failed private setup has no ordinary-store fallback.
- Unit TestHostArguments should be `--mfv-unit-tests --mfv-test-session <fresh UUID>`, or its valid `MFV_TEST_SESSION` environment plus explicit unit flag. An automatically detected XCTest host without an explicit request creates one process-local UUID. Unit hosts show `mfv.private.unit` before Schema, ModelContainer or ContentView is created. Root should verify the actual host launch mode in the generated plan rather than rely solely on test-framework detection.
- Invalid/missing/conflicting private UUIDs or modes show only `mfv.private.invalid`. Old `--uitesting`, `-qaStore`, and `-qaStoreName` requests without a valid UUID are rejected. They cannot fall back to ordinary preferences or stores.
- Release configuration always resolves `.normal`; original persisted local SwiftData, standard app preferences and temporary export behavior are retained. Project versions, entitlements, original artwork and backend configuration are unchanged.
- Active private UI does not construct sayings providers or Image Playground. Photos/import buttons and printing are disabled. The new tests never use account, CloudKit, API, subscription, Photos or print service methods. ShareLink file controls remain present, but these prepared tests do not choose a destination or send anything.
- Shared unit ModelContainer fixtures are memory-only and now explicitly `cloudKitDatabase: .none`. Existing CardDraftTests use fresh UUID temporary directories and their explicit CloudKit-none configurations. Existing API/CloudKit/subscription integration tests are not selected.

## Proposed compilation

Commands are recommendations for root, not execution records. Use a fresh derived-data/result directory, and preserve logs/products and all failures. No visionOS destination is allowed.

```sh
xcodebuild -project 'My Funny Valentine.xcodeproj' -scheme 'My Funny Valentine' \
  -configuration Debug -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/mfv-creative-qa-20261004 \
  -jobs 2 -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO build-for-testing
```

```sh
xcodebuild -project 'My Funny Valentine.xcodeproj' -scheme 'My Funny Valentine' \
  -configuration Debug -destination 'generic/platform=macOS' \
  -derivedDataPath /tmp/mfv-creative-mac-20261004 \
  -jobs 2 CODE_SIGNING_ALLOWED=NO build
```

The existing app, unit and UI folders are file-system-synchronized target groups. No project membership edit is required for the new files. Generic compile success would not establish native UI behavior, printing or share presentation.

## Proposed exact runtime selection

After an owned headless Phone is explicitly allocated, read its available/Shutdown state. Snapshot ordinary app files and preferences, hash the held shipping/test map and generated app/test products, and validate unit host/session arguments before boot. Keep unit and UI launch flags separate. UI methods provide their own valid UUID flags; a blanket `--mfv-unit-tests` flag must not be injected into their app launches. Enumerate before execution, use jobs2/no parallel tests, and never count a zero-test result as a pass.

Run these two new unit classes only first, expecting thirteen methods:

```text
My Funny ValentineTests/CreativeCardExportTests
My Funny ValentineTests/MFVRuntimeIsolationTests
```

The seven export methods are `backwardCompatibleLayoutsAndStarters`, `snapshotDoesNotReadLiveDraft`, `fullCardAnimation`, `calmMotionAndOpening`, `printablePDF`, `transparentSticker`, and `safeOfflineBrowserCard`.

The six isolation methods are `validUISession`, `malformedPrivateRequests`, `conflictingRequests`, `unitHostsAreBlank`, `ordinaryAndForcedModes`, and `actualPrivateUnitPaths`.

For bounded regression coverage, nine existing methods are in `CardRendererTests`, `CardDraftTests`, `CardPersistenceRegressionTests`, and `StarterTemplateCatalogTests`. Inspect their actual enumeration and private memory/temp fixture contracts before execution. Old broad test suites and old UI tests are excluded.

The three new genuinely native methods are:

```text
My Funny ValentineUITests/CreativeCardsUITests/testSixStarterFamiliesOpenAndClose
My Funny ValentineUITests/CreativeCardsUITests/testSavedMotionChoiceAndLocalExportSheet
My Funny ValentineUITests/CreativeCardsUITests/testInvalidPrivateSessionRemainsBlank
```

They are prepared, uncompiled and unrun. The first opens all six actual first starters and checks front/inside/close, family selection and disabled provider/photo actions. The second edits a fictional personal card, persists motion-off, relaunches into the same private session, reopens the real card and generates local front/inside PNG, full-card GIF, PDF, sticker PNG and HTML through their actual export buttons. The third proves rejection before any ordinary app controls appear. Native screenshots and complete accessibility text are attached before actions and on missing/ambiguous controls. Screenshot capture uses `XCUIScreen.main.screenshot()`; no app screenshot crop substitution or fabricated pixels is used.

Stop and preserve the actual first failure. Do not repair source or selectors silently. A fresh Phone result must be reviewed before supported Pad or Mac UI coverage is approved. The methods do not prove drag behavior, Reduce Motion, largest text, dark appearance, Mac keyboard/window behavior, native print presentation or actual ShareLink chooser presentation. Those remain later bounded checks. Root can inspect generated private Media file hashes/decodes after Shutdown alongside the independent unit decode tests.

Always terminate only the owned app, restore any specifically authorized device changes, and finally shut down only the allocated device. Compare normal-data and source/product guards, then export xcresult summaries, activities, AX text and images sequentially after Shutdown. No simulator app activation, OS preferences, real user store cleanup, remote provider invocation, new sign-in flow, physical hinge claim or visionOS work is authorized by this plan.
