# My Funny Valentine release draft

Updated 2026-10-03. This file describes frozen native revision `bff4771b52f9b13eb7a44af88be8311496bd412b` and proposed App Store copy. Signed iOS/Mac packages and 30 composed marketing images passed local verification. Native save/relaunch flows, actual Mac Apple generation and a synthetic pre-polish saved-card upgrade passed. Xcode could not create the missing App Store record, so no upload, processing or review submission is verified.

## Release scope

The home screen contains 30 editable starters across six illustrated collections. Photos are optional. Each card starts as an unsaved draft; Save commits it to the local library. The editor can add a photo or a detected face, preview the result, share a PNG and export a face animation as a GIF on iOS and macOS.

Face detection runs locally with Vision. Foreground masking uses the available system model; a padded photo crop remains the fallback. Only the added face moves in the face GIF.

Built-in cards, manual editing and built-in message suggestions work offline. Optional FoundationModels sayings require iOS 26 or macOS 26, eligible hardware, enabled Apple Intelligence and a ready model. Unavailable or failed generation uses built-in messages, which must not be presented as AI output.

Optional artwork uses the interactive Image Playground system sheet. Apple manages availability, processing and usage limits, and the sheet may use Private Cloud Compute. Artwork generation must not be described as guaranteed offline, entirely on-device or unlimited. The app uses the sheet rather than the discontinued ImageCreator class. See [Apple's migration notice](https://developer.apple.com/news/?id=dz9wvq0r) and [Image Playground guidance](https://developer.apple.com/videos/play/wwdc2026/375/).

Saved cards, photos and settings use persistent local storage. Cards use SwiftData; the welcome preference uses UserDefaults. The existing card schema and default store location are preserved. There is no automatic cross-device sync. A storage-open failure displays a retry screen; the app does not report successful saves into a temporary memory store.

The default app has no hosted backend configured. It is free with no in-app purchases, ads or app account. visionOS work remains paused by the owner's instruction.

## Identity and availability

| Field | Draft or configured value | Verification |
|---|---|---|
| Name | My Funny Valentine | App Store Connect pending |
| Bundle ID | com.nathanfennel.My-Funny-Valentine | Current project |
| Development team | EJLR2RPSV2 | Final bff4771 distribution signatures verified |
| Version and build | 1.0, build 1 | Final exported payloads verified; App Store record pending |
| Platforms | iPhone, iPad, Mac | Complete Phone/Pad flows and manual native Mac checks passed |
| iOS and iPadOS minimum | 18.0 | Final payload verified; representative18.5 runtime23/23 passed. Exact18.0 unavailable |
| macOS minimum | 15.1 | Final payload and static framework availability verified; exact15.1 runtime unavailable |
| Primary category | Photo & Video | Proposed, App Store Connect pending |
| Secondary category | Lifestyle | Proposed, App Store Connect pending |
| Price | Free in every enabled storefront | App Store Connect pending |
| Availability | All supported storefronts Apple permits | App Store Connect pending |
| In-app purchases | None | Current native flow has none; App Store Connect verification pending |
| Age rating | Complete the questionnaire for the signed build | Pending |
| App ID, SKU and review contact | Read the owner's actual App Store Connect record | Pending |

The prior macOS minimum was 26.2. Lowering the setting is not proof that the app runs on 15.1.

## App Store copy

Locale: en-US. The machine-readable draft is [release-listing.json](../app-store-audit/2026-10-03-my-funny-valentine/release-listing.json). Check the final copy against the frozen signed build before entering it.

### Subtitle

Funny cards, made yours

### Promotional text

Pick a playful card, make the message yours, and send a smile. Thirty editable starters, optional photos and face animation. Free, with no in-app purchases.

### Description

Send a card that sounds like you.

Start with one of 30 editable cards across six playful collections: Pizza Crush, Cosmic Love, Lovebirds, Dino-mite, Disco Date and Sweet Tooth. Each collection has original illustrated artwork and five different messages. Pick your favorite and make the words yours.

MAKE IT PERSONAL
• Edit the message and add a personal note
• Add a photo, or choose a face from your photo
• Make and save cards without adding a photo
• Find a message with built-in suggestions or optional Apple Intelligence on compatible devices

READY TO SEND
• Preview your card before sharing
• Share a card image with the native share sheet
• Add a playful face animation and share it as a GIF

YOUR CARD LIBRARY
• Save cards on the device where you make them
• Reopen a card to edit it or send it again
• Browse the starter cards and edit your own messages offline

Optional Image Playground artwork is available on supported Apple Intelligence devices. Apple manages its availability, processing and usage limits. Built-in cards, your own messages and photo editing remain available without it.

My Funny Valentine is free, with no in-app purchases, ads or app account.

### Keywords

valentine,card,greeting,love,funny,romantic,photo,face,gif,anniversary,message,art

A first release does not need a fabricated update history. The version history field is left unset in the draft.

## Review notes

No demo account is required. The app is free and has no in-app purchases or ads.

The app opens directly to 30 editable starter cards. Choose a card, edit its message or personal note, then Save. My Cards contains the cards explicitly saved by the user. Cancel leaves the saved card unchanged.

Photos are optional. Photo adds an image. Face detects faces locally with Apple's Vision framework. Foreground masking is used where available; a photo crop is the fallback. From Share, a card with an added face can use Animate face and share a GIF. Only the added faces move.

Find the words offers built-in messages. Optional FoundationModels generation needs iOS 26 or macOS 26, eligible hardware, enabled Apple Intelligence and a ready model. If generation is unavailable or fails, built-in suggestions remain available.

Image Playground appears only when the Apple system reports support. Apple manages this optional generation sheet, which may use Private Cloud Compute and Apple-managed limits. It is not guaranteed to work offline. The app imports the completed image into the card.

This build has no hosted backend configured. Saved cards and their photos use persistent local storage on this device. There is no cross-device synchronization. If storage cannot open, the app shows a retry screen instead of using temporary memory storage.

## Privacy and owner details

These are proposed URLs, not verified live release links:

| Purpose | Proposed URL |
|---|---|
| Privacy | https://nathanfennel.com/my-funny-valentine/privacy.html |
| Support | https://nathanfennel.com/my-funny-valentine/support.html |

The App Store marketing URL stays unset because there is no app directory marketing page.

The privacy page must describe local saved cards, on-device face detection and the optional Apple generation paths accurately. Publishing and live URL verification remain separate release work. This native release draft does not deploy a website.

The 72 website pages are committed at `ec90d6f42769093fa43f0dbd1252fa2150036a1d` and are not deployed. The read-only `fishbowl-head` AWS check at 04:06:16 UTC on October 3 reported expired CLI credentials. Neither new release URL is verified live. Use the website repository's verified dual-deployment command after authentication is restored; a Vercel-only release or Git push does not satisfy the workspace policy.

The proposed label is Data Not Collected, with its final-build and Apple-framework rationale in [privacy-label-rationale.json](../app-store-audit/2026-10-03-my-funny-valentine/privacy-label-rationale.json). This proposal is unpublished. There is no configured hosted generation service in this build. Apple-managed processing in Image Playground is distinct from developer collection; the privacy page describes it. Owner publication and any legal attestation remain action-time steps.

Review contact details must come from the owner's existing record. Apple agreements, export-compliance answers and any required owner attestations remain pending until the corresponding release information is reviewable and verified.

## Galleries

The July 21 galleries have obsolete iCloud captions and old Settings screens. Preserve them as historical files; do not upload them for this release.

Ten composed marketing images are complete for each Phone, iPad and Mac gallery. Each uses that platform's actual native captures from frozen bff4771. They have short centered top copy, three real app captures, an upright centered hero, outward supporting fans and four alternating background designs.

The first three images show choosing a starter, editing a message and the finished share preview. The Mac editor/share images include the actual fictional-face cutout. Simulator sayings show built-in suggestions; the Mac sayings image shows actual FoundationModels output. Final dimensions are 1320 by 2868 for iPhone, 2752 by 2064 for landscape iPad and 2560 by 1600 for Mac, checked against [Apple's screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/). App Store acceptance and the actual uploaded gallery remain unverified.

Ten accepted originals each for iPhone, landscape iPad and Mac are captured from frozen bff4771. The complete Phone/Pad flows passed actual message entry, native keyboard Done, save, relaunch and selected sayings. The Mac gallery comes from actual native controls; its library, face, share preview, sayings and Image Playground import were checked manually. All 30 final JPEGs passed technical and two visual reviews. [The manifest](../app-store-audit/2026-10-03-my-funny-valentine/marketing-bff4771/manifest.json), [provenance](../app-store-audit/2026-10-03-my-funny-valentine/marketing-bff4771/exports/marketing-provenance.json) and [QC receipt](../app-store-audit/2026-10-03-my-funny-valentine/marketing-bff4771/marketing-qc.json) identify every accepted original and output.

The first iPad functional flow passed, but its app-bounds captures encoded sideways content and a black strip. Those originals remain rejected diagnostics. The replacement full device-screen flow passed and captured complete native screens. Standard ImageIO handling of their EXIF orientation produces upright landscape images; no source pixels were repaired or replaced, and original bytes remain unchanged.

Three earlier iPhone attempts failed the keyboard-dismissal postcondition. The native multiline field now has a Done control; the unchanged postcondition passed on both iPhone and iPad. Keep those failed attempts as historical evidence.

## Verification and release gates

| Check | Current evidence |
|---|---|
| Frozen-source iOS build-for-testing | bff4771 succeeded; `/tmp/mfv-ios-build-keyboarddone-20261003.log` |
| Frozen-source macOS native build | bff4771 development-signed QA build succeeded; `/tmp/mfv-macos-build-keyboarddone-20261003.log` |
| Earlier selected native tests | iOS 22 core checks and one starter UI flow passed. Mac 20 other core checks passed, then the corrected draft-lifecycle test passed separately |
| Mac automated UI checks | Both unsigned and signed runner setups failed before tests; signed setup timed out enabling automation mode |
| Current saved cards and relaunch | Full Phone/Pad gallery flows passed save/reopen/relaunch. Manual Mac cold launch retained six saved cards and the original face/message/note after cancelled exploration |
| Existing pre-polish saved-card preservation | Synthetic old committed local model store reopened/saved/cold-reopened with current models and production CardDraft on Mac 26.5.2. Persistent identities, membership, text and raw media/layout bytes retained. No real production or CloudKit upgrade verified |
| iPhone, landscape iPad and Mac visual checks | Ten accepted originals per platform and all 30 composed outputs passed; rejected first iPad captures retained separately |
| Large text, light/dark appearance and narrow windows | Broader runtime checks pending |
| Face crop, foreground matte and GIF result | Simulator CPU face inference/crop passed. Actual Mac face import and visible alpha passed; native PNG/GIF payload proof at 76d9986b is retained with its exact earlier-source scope |
| Apple generation on eligible hardware | Native Mac FoundationModels suggestions generated and selected into draft; system Image Playground Apple Animation image generated and imported at bff4771 |
| iOS18/macOS15.1 compatibility | Representative iOS18.5 run passed23/23 on frozen native source. Final signed binaries and use-site gates passed static audit. Exact18.0/Mac15.1 runtimes unavailable |
| Fresh native marketing galleries | 30 final JPEGs passed dimensions, sRGB, hashes, size and two visual reviews; upload verification pending |
| Signed archives and icons | Final bff4771 iOS IPA and universal Mac PKG local signatures, manifests, metadata and hashes verified; prior3d616369/9253975 retained historically |
| Build upload and processing | Historical CLI attempts failed before transfer. Final bff4771 Xcode validation could not create the missing app record, reporting DistributionAppRecordProviderError0. No app ID, transferred/selectable build or processing verified |
| App Store Connect metadata, pricing and countries | Pending |
| Privacy label, legal fields and live URLs | Pages prepared, deployment blocked by expired AWS CLI login; owner label/rights/legal/contact steps pending |
| Review submission | Pending |

The old 89-test and zero-warning claims are removed. Empty CloudKit, API and critical-flow test bodies do not verify those capabilities. [native-verification.json](../app-store-audit/2026-10-03-my-funny-valentine/native-verification.json) retains historical core/storage results and the current bff4771 gallery results. The [source fingerprint](../app-store-audit/2026-10-03-my-funny-valentine/native-source-fingerprint.json) records all111 native files and aggregate SHA256 `ac605b6b0f9fbec8ff02f1ed856bbdad9d91bdae3c055fa4a08d6c3a0817a1cf`.

[signed-archives.json](../app-store-audit/2026-10-03-my-funny-valentine/signed-archives.json) records the historical3d616369 packages and failed upload attempts. [signed-archives-9253975.json](../app-store-audit/2026-10-03-my-funny-valentine/signed-archives-9253975.json) preserves the superseded9253975 packages. Neither was successfully uploaded.

The [native Mac export receipt](../app-store-audit/2026-10-03-my-funny-valentine/qa-exports/native-mac-export-receipt.json) inspects actual PNG/GIF payloads from the76d9986b binary. Visible text remains complete; animation differences are confined to the face. That earlier payload proof does not establish a successful Mac UI XCTest run or later binary export verification.

The [current native system-generation receipt](../app-store-audit/2026-10-03-my-funny-valentine/qa-exports/native-mac-system-generation-bff4771.json) records real Mac sayings selection, completed Image Playground artwork import and Cancel/cold-launch preservation. Only a generic food phrase was supplied to Apple; no personal suggestion, source photo or external provider was selected. Availability on that Mac does not prove availability on other hardware or minimum operating systems.

The [final signed-package receipt](../app-store-audit/2026-10-03-my-funny-valentine/signed-archives-bff4771.json) identifies the distribution IPA and universal Mac App Store PKG. The [legacy-upgrade receipt](../app-store-audit/2026-10-03-my-funny-valentine/legacy-upgrade-verification.json) records the synthetic local test and its limits. The [managed registration receipt](../app-store-audit/2026-10-03-my-funny-valentine/managed-store-registration-bff4771.json) records Apple's failed app-record creation before transfer; its cause is not established.

Chrome is blocked by an existing unsaved-page warning. Safe Cancel actions did not dismiss it. The owner was asked to click Cancel to preserve that page and sign in to App Store Connect in a separate tab. No draft was discarded. Append upload processing and App Store Connect verification when access is restored. Successful compilation or packaging never implies submission.

The [iOS18.5 compatibility receipt](../app-store-audit/2026-10-03-my-funny-valentine/ios18-compatibility-verification.json) records all23 passing checks on the oldest installed representative iOS runtime. The [static minimum-OS receipt](../app-store-audit/2026-10-03-my-funny-valentine/minimum-os-static-verification.json) verifies final signed framework loading and source gates. The [local website receipt](../app-store-audit/2026-10-03-my-funny-valentine/website-local-verification.json) records complete phone/desktop page rendering; neither local rendering nor prepared files prove live deployment. A separate working Codex Apple sign-in tab is marked for owner handoff.
