# Creative-card marketing framework

Thirty final images have been rendered and individually approved by root for native version 1.0 build 3, source-freeze.root-r8.json. See render-proof.json for exact inputs, output dimensions, hashes and review. All thirty images were uploaded to the iPhone 6.9-inch, iPad 13-inch landscape and Mac galleries in English (U.S.). Batch upload order was corrected through Apple’s keyboard drag controls, then verified in exact 01–10 order after full reloads. Both native 1.0(3) versions are Waiting for Review. See [the upload receipt](../release/marketing-upload-verification.json).

The manifest has ten slots per platform, with seven multi-capture and three single-capture compositions. Four deliberate backgrounds alternate: coral/burgundy heart prints, cosmic indigo stars, mint confetti, and plum envelope geometry. The card's existing pink/burgundy identity remains the anchor. Fraunces provides a rounded, expressive serif headline; its unmodified variable font and SIL Open Font License are bundled in this audit folder. [The primary font license](https://raw.githubusercontent.com/google/fonts/main/ofl/fraunces/OFL.txt) permits embedding and distribution with the retained notice.

The six family fronts lead the gallery. An inside card, library, personalized card and local export workflow complete it. Headlines name emotional value without claiming provider generation, physical hinge input, automatic sending, cloud sync or a registered chat sticker extension. The photo-booth panel describes its print style and does not imply a user photo was imported in private QA. The export panel's copy stays general until actual output/chooser evidence is reviewed.

Every composition uses a centered upright hero and zero, one or two distinct genuine supporting captures. Left support rotates counterclockwise and right support clockwise. Images preserve their full aspect ratio; browser decode must match documented EXIF display dimensions. The hero is reduced if needed to keep its complete native interface within the canvas. Supporting images may extend past the canvas edges. No app text, control, frame or artwork is redrawn inside a capture. Native Mac screenshots require their own explicit full-scene or component provenance. CUA returned JPEG originals on Mac; the native .jpg files retain their original bytes. Phone and iPad originals are PNG.

The output targets are 1320×2868 Phone, 2752×2064 landscape iPad and 2560×1600 Mac. The iPad canvas matches the genuine landscape capture display ratio; retain its original encoded PNG and EXIF orientation. Root freshly verified 2752×2064 as an accepted 13-inch size in Apple’s [screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications/). Root verified native build 3 and English (U.S.) in each editable version before submitting. The prepared manifest retains its earlier preparation wording as a historical rendering input; the separate final upload receipt records completed store work.

## Matching capture handoff

Root should supply ten useful actual states per platform if available: `comic-front`, `cosmic-front`, `loveLetter-front`, `popUp-front`, `photoBooth-front`, `confetti-front`, `inside`, `library`, `personalized`, and `exports`. Each record must identify platform, encoded/display dimensions, original filename/SHA256, native version/build, test/xcresult or component proof, capture API and exact source/build receipt. Old build screenshots are not substitutes. No UUID text or test marker may be visible in the marketing content.

Copy byte-identical native files under `native/<platform>/` and the final root freeze under `proof/`. Fill `manifest.captures` using `<platform>-<state>` IDs. Fill the exact version/build and root sourceFreeze snapshot/hash. Mark each platform `root-matching-native-handoff` only after its actual handoff. Set `preparationState` to `native-capture-inputs-approved` only after checking all sources. Pending Mac sources may not be filled with Phone/iPad UI.

The renderer stops before loading a browser dependency while the manifest is pending. Once approved, it verifies all listed shipping input hashes before and after rendering, original PNG/JPEG hashes, orientation, distinct support pixels, centered hero, fan directions, headline margins/separation and exact opaque output dimensions. It uses an existing headless Chromium for artifact generation, blocks external requests and never controls a native app or user browser. Root's later native source changes require a new actual derivative freeze, not rewriting the earlier prepared snapshot.

For future revisions, after a real handoff, render in one platform batch, inspect each export once and record any concrete defects. Correct those together and confirm at most one more batch. Root retains separate visual approval and upload responsibility. The renderer initially returns `rendered-awaiting-individual-review-and-root-approval`; root subsequently recorded individual approval and authenticated store uploads separately. Neither rendering nor a filename alone proves submission.

```sh
node render-marketing.cjs
```

Use the already installed Playwright runtime/dependency path when executing. No dependency installation, user browser, native build, provider or paid compute is part of this framework.

## Reference scope

The owner's attached example sets centered headline/hero and outward fans. The previously approved MFV October 3 gallery supplies incumbent color/shape and size evidence. The official [Ink Cards listing](https://apps.apple.com/us/app/ink-cards-send-custom-cards/id477296657) and [Canva listing](https://apps.apple.com/us/app/canva-ai-photo-video-editor/id897446215) were reopened for category and gallery-link research. Text extraction exposed their published descriptions and image-link inventory, not fresh screenshot pixels. No unviewed competitor layout is claimed as visual evidence, and none of their imagery or commercial fulfillment features is copied.
