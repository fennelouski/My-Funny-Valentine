# My Funny Valentine release draft

Updated 2026-10-03. This file describes the current source and proposed App Store copy. It is not a submission receipt. The final signed build, native captures and App Store Connect fields still need verification.

## Release scope

The home screen contains 30 editable starters across six illustrated collections. Photos are optional. Each card starts as an unsaved draft; Save commits it to the local library. The editor can add a photo or a detected face, preview the result, share a PNG and export a face animation as a GIF on iOS and macOS.

Face detection runs locally with Vision. Foreground masking uses the available system model; a padded photo crop remains the fallback. Only the added face moves in the face GIF.

Built-in cards, manual editing and built-in message suggestions work offline. Optional FoundationModels sayings require iOS 26 or macOS 26, eligible hardware, enabled Apple Intelligence and a ready model. Unavailable or failed generation uses built-in messages, which must not be presented as AI output.

Optional artwork uses the interactive Image Playground system sheet. Apple manages availability, processing and usage limits, and the sheet may use Private Cloud Compute. Artwork generation must not be described as guaranteed offline, entirely on-device or unlimited. The app uses the sheet rather than the discontinued ImageCreator class. See [Apple's migration notice](https://developer.apple.com/news/?id=dz9wvq0r) and [Image Playground guidance](https://developer.apple.com/videos/play/wwdc2026/375/).

Saved cards, photos and settings use persistent local SwiftData storage. The existing schema and default store location are preserved. There is no automatic cross-device sync. A storage-open failure displays a retry screen; the app does not report successful saves into a temporary memory store.

The default app has no hosted backend configured. It is free with no in-app purchases, ads or app account. visionOS work remains paused by the owner's instruction.

## Identity and availability

| Field | Draft or configured value | Verification |
|---|---|---|
| Name | My Funny Valentine | App Store Connect pending |
| Bundle ID | com.nathanfennel.My-Funny-Valentine | Current project |
| Development team | EJLR2RPSV2 | Current project, archive signing pending |
| Version and build | 1.0, build 1 | Current project, release numbering pending |
| Platforms | iPhone, iPad, Mac | Current project, native checks pending |
| iOS and iPadOS minimum | 18.0 | Current project, oldest-OS runtime check pending |
| macOS minimum | 15.1 | Newly configured, latest compilation and 15.1 runtime check pending |
| Primary category | Photo & Video | Proposed, App Store Connect pending |
| Secondary category | Lifestyle | Proposed, App Store Connect pending |
| Price | Free in every enabled storefront | App Store Connect pending |
| Availability | All supported storefronts Apple permits | App Store Connect pending |
| In-app purchases | None | Verify final signed build and App Store Connect |
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

Prepare App Privacy answers from the final signed build before publishing the label. There is no configured hosted generation service in this build. Do not copy the older subscription, backend-upload or CloudKit claims. Apple-managed processing in Image Playground is distinct from developer collection and needs accurate wording.

Review contact details must come from the owner's existing record. Apple agreements, export-compliance answers and any required owner attestations remain pending until the corresponding release information is reviewable and verified.

## Galleries

Replace the July 21 galleries. Their iCloud captions and old Settings screens are obsolete. Current files have six Phone, six iPad and three Mac images; they are not current release evidence.

Prepare ten composed marketing images for each Phone, iPad and Mac gallery. Each must use that platform's actual native capture from the frozen build. Use short centered top copy, one to three real app captures, an upright centered hero and outward supporting fans when present. Rotate three to four distinct background designs between adjacent images.

The first three images should show choosing a starter, editing a message and the finished share preview. Photo and face-animation images need genuine native results. Do not present a Simulator placeholder as successful Apple Intelligence or Image Playground generation. Validate Apple's accepted dimensions and inspect the actual uploaded gallery before submission.

Fresh capture, composition, gallery review and upload are pending.

## Verification and release gates

| Check | Current evidence |
|---|---|
| iOS build-for-testing | Release owner reports success before the latest storage and minimum-OS edits |
| macOS build-for-testing | Release owner reports success before the latest storage and minimum-OS edits |
| Latest-source builds | Pending |
| Native test execution | Pending |
| Save, Cancel, failed-save and relaunch behavior | Pending current native verification |
| Existing saved-card preservation | Schema and store path unchanged; upgrade/reopen verification pending |
| iPhone, iPad and Mac visual checks | Pending |
| Large text, light/dark appearance and narrow windows | Pending |
| Face crop, foreground matte and GIF result | Pending native verification |
| Apple generation on eligible hardware | Pending |
| macOS 15.1 runtime compatibility | Pending |
| Fresh native marketing galleries | Pending |
| Signed archives and icons | Pending final archive verification |
| Build upload and processing | Pending |
| App Store Connect metadata, pricing and countries | Pending |
| Privacy label, legal fields and live URLs | Pending |
| Review submission | Pending |

The old 89-test and zero-warning claims are removed. Empty CloudKit, API and critical-flow test bodies do not verify those capabilities. Current storage and catalog tests need recorded execution, not just successful compilation.

The release owner will append exact source revision, commands, result bundles, signed archive identities, native capture provenance, upload processing and App Store Connect verification after the source freeze. No build or submission status should be inferred from this draft.
