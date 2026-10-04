# Current root-r8 Mac export QA

Pass within the reviewed file scope: native My Funny Valentine 1.0 (3), source freeze `7b7535d15d7c78c641068594a9c317562a153b4124ce689e65632a3822dc87ca`. All six actual Mac exports independently match their source manifest hashes and remain unchanged.

The front PNG, GIF front frames and PDF page 1 preserve both birds’ heads. The inside PNG, actual GIF frame 15 and PDF page 2 show the entire note: “You make ordinary days wonderful. Love, Sam.” The transparent sticker preserves the full **front headline**, not the inside note.

- Front and inside PNG: 800 × 1200, fully opaque RGBA.
- Sticker PNG: 618 × 618, alpha 0–255, 33,370 bytes, under 500 KB.
- Full-card GIF: 400 × 600, 30 decoded frames at 100 ms each, 3 seconds total. Frames 0, 15 and 29 were extracted and individually viewed.
- PDF: both complete 288 × 432 pt pages were rendered at 150 dpi and individually viewed; title, artwork and full message are readable.
- HTML: 16 independently decoded embedded 400 × 600 PNGs; restrictive CSP, no external URLs/network API references, full title/message fallback, reduced-motion handling and saved motion-off preference. Browser interaction remains root-owned.

Eight images were individually viewed. [verification.json](verification.json) records the actual Mac source/preview hashes, commands, private process provenance and scope. No iPhone images were substituted. This file check does not establish all-six-family scene, keyboard, persistence, printing, sending or provider behavior; those remain separate root evidence.

:codex-file-citation{path="/Users/nathan/Documents/GitHub/My-Funny-Valentine/app-store-audit/2026-10-04-creative-cards/native-exports/mac-final-r8/Valentine-18B8B929-B2EF-421E-A791-B5ADB49C7E9A.pdf" purpose="source"}
