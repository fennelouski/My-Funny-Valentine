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

## Outstanding release work

Xcode reported that no App Store record exists for this bundle and failed to create it before validation or binary transfer. See [managed-store-registration-bff4771.json](managed-store-registration-bff4771.json). Its underlying cause is not established. Chrome's existing unsaved-page warning was preserved; a separate working Codex Apple sign-in tab is waiting for the owner.

The privacy and support pages passed local phone/desktop rendering, but remain undeployed at website revision `ec90d6f42769093fa43f0dbd1252fa2150036a1d`. AWS CLI profile `fishbowl-head` is expired. The website must use its verified AWS and Vercel deployment command from one clean committed revision.

App Store metadata, free pricing, all permitted storefronts, build processing, gallery acceptance, owner legal/privacy/contact attestations and review submission remain unverified. The source and local packages are ready for those steps; this folder is not a submission receipt.
