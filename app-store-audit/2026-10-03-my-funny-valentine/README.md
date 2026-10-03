# My Funny Valentine release evidence

The frozen native app is `bff4771b52f9b13eb7a44af88be8311496bd412b`, version 1.0, build 1. All 111 native files match aggregate SHA256 `ac605b6b0f9fbec8ff02f1ed856bbdad9d91bdae3c055fa4a08d6c3a0817a1cf`. Later test-harness, compositor and audit commits do not change the packaged app source.

The complete iPhone and iPad flows passed. Manual Mac checks passed, including real FoundationModels sayings, an Image Playground artwork import and preservation of saved cards after Cancel and cold launch. The oldest installed representative iOS 18.5 run passed 23 checks. Exact iOS 18.0 and macOS 15.1 runtimes were unavailable; exported binaries and source availability gates passed static verification.

A synthetic local store written with pre-polish committed model sources reopened, saved and cold-reopened with the current models and production CardDraft. This verifies local model compatibility on the current Mac, without opening a user's production store or claiming a CloudKit transition.

Final distribution packages are identified in [signed-archives-bff4771.json](signed-archives-bff4771.json). The IPA and universal Mac App Store installer passed local signature, architecture, minimum-OS, privacy-manifest and hash checks. These checks do not prove Apple processing or review submission.

## Marketing files

Upload only the 30 JPEGs in `marketing-bff4771/exports/iphone-6.9`, `ipad-13` and `mac`, ten per platform. They passed two visual reviews and technical checks at 1320 by 2868, 2752 by 2064 and 2560 by 1600 respectively. The manifest and provenance identify every genuine native source and preserve its original hash.

The first iPad app-bounds captures remain rejected diagnostics. The accepted `captures/ipad-screen-bff4771` originals come from the full native device screen. Standard ImageIO orientation handling renders their complete landscape pixels. The compositor does not repair screenshots or draw replacement app content.

Validate the manifest from the repository root:

```sh
swift scripts/make-marketing-images.swift --validate app-store-audit/2026-10-03-my-funny-valentine/marketing-bff4771/manifest.json
```

To reproduce composition, copy the manifest and set a new empty output directory within `app-store-audit`, then run the same command without `--validate`. Existing output files are preserved.

## App Store Connect progress, October 3

Normal browser access recovered and confirmed App Store Connect record `6818700756`, bundle and SKU `com.nathanfennel.My-Funny-Valentine`. The earlier registration failure is historical. The iOS 1.0 (1) package uploaded, processed and was selected and saved.

Apple rejected the original Mac package before transfer because its category key was missing. Revision `c8312d107cfd1040db30b07036d81896d1fdf7e3` adds only `LSApplicationCategoryType=public.app-category.photography` to the native source. Mac 1.0 (2) uploaded, processed and was selected and saved. The original captures still match all display source and assets; the category change is recorded separately from their frozen provenance.

All 30 marketing JPEGs are uploaded, saved in order and visually checked against Apple's hosted previews: ten iPhone, ten iPad and ten Mac. Four backgrounds alternate and adjacent hero artwork differs. Source-backed descriptions, support links, review notes and the owner's supplied review contact are saved. Sign-in is not required. Categories, subtitle and the content questionnaire are saved. Pricing is Free and all 175 available storefronts are enabled for release after approval.

Unlisted support and privacy pages are deployed on AWS and Vercel from website revision `5c00d3f8ddbc48fa62f8504c527128a0ae8fa75b`. The website deployment receipt verifies HTTP 200 and identical source hashes on both hosts. The earlier expired-AWS and undeployed-page statements are superseded.

Both platform Add for Review checks report one remaining App Store Connect requirement: publish App Privacy. The reviewed Data Not Collected draft and policy URL are saved. A precise owner accuracy/compliance approval question is pending; do not repeat it or publish without its answer. Neither platform has been submitted for review.

Current upload, capture-parity, gallery and final validation receipts are in `/Users/nathan/Documents/GitHub/app-store-audit/2026-09-27-release/goal-release-2026-10-02/valentine-*2026-10-03.json`. The authoritative account reconciliation and pending approval are in that release ledger. This packet is preparation and validation evidence, not a review-submission receipt.
