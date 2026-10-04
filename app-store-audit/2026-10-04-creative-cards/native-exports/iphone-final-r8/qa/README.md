# Current root-r8 iphone export QA

Pass within the reviewed file scope: native My Funny Valentine 1.0 (3), source freeze `7b7535d15d7c78c641068594a9c317562a153b4124ce689e65632a3822dc87ca`. All six current platform exports independently match their source manifest hashes and remain unchanged.

The front PNG, GIF front frames and PDF page 1 preserve both birds’ heads. The inside PNG, actual GIF frame 15 and PDF page 2 show the full message: “You make ordinary days wonderful. Love, Sam.” The transparent sticker preserves the complete **front headline**; it does not contain the inside note.

- Front and inside PNG: 800 × 1200, fully opaque RGBA.
- Sticker PNG: 618 × 618, alpha 0–255, 27,319 bytes, under 500 KB.
- Full-card GIF: 400 × 600, 30 decoded frames at 100 ms each, 3 seconds total. Actual frames 0, 15 and 29 were extracted and individually viewed.
- PDF: all two pages are 288 × 432 pt. Both complete pages were rendered at 150 dpi and individually viewed; full title, artwork and message are readable.
- HTML: 16 independently decoded embedded 400 × 600 PNGs; restrictive CSP and no external URL/network API references, complete title/message and readable fallback. Source includes reduced-motion handling and this fixture’s saved motion-off preference. Actual browser interaction remains root-owned.

Eight images were individually reviewed for this platform. [verification.json](verification.json) records exact original/preview hashes, commands, private native provenance and scope. The earlier r6 crop failure and superseded r7 QA remain unchanged. This receipt covers current root-r8 files; it makes no macOS, all-six-family scene, printing, sending or provider claim.

:codex-file-citation{path="/Users/nathan/Documents/GitHub/My-Funny-Valentine/app-store-audit/2026-10-04-creative-cards/native-exports/iphone-final-r8/Valentine-44F60F4F-1939-4206-8AD6-7E4354BC353F.pdf" purpose="source"}
