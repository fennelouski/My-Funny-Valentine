# Final root-r7 iPhone export QA

Pass within the reviewed file scope. All six native build 3 exports match their original manifest hashes and were left unchanged. The former birds-head crop is corrected in the front PNG, actual GIF front frames and PDF page 1. The inside PNG, sticker and PDF page 2 preserve the full message.

- Front and inside PNGs: 800 × 1200, opaque RGBA.
- Sticker: 618 × 618, genuine transparency, 27,319 bytes.
- GIF: 400 × 600, 30 actual frames, 100 ms each, 3 seconds total. Frames 0, 15 and 29 were decoded and individually viewed.
- PDF: both complete 288 × 432 pt pages were rendered at 150 dpi and individually viewed. Full title and message are readable.
- HTML: 16 verified embedded PNG frames, 400 × 600 each; self-contained source with restrictive CSP, no external resource URLs or network API references, readable message fallback and reduced-motion handling. Browser interaction remains root-owned.

Eight images were reviewed individually. Exact source, preview and evidence hashes, command receipts, native attribution and limits are in [verification.json](verification.json). This QA does not establish all-six-family scene coverage, macOS runtime, printing, sending or provider behavior. The earlier r6 crop-failure receipt and artifacts remain unchanged under `../../iphone/qa/`.

:codex-file-citation{path="/Users/nathan/Documents/GitHub/My-Funny-Valentine/app-store-audit/2026-10-04-creative-cards/native-exports/iphone-final-r7/Valentine-C48B8075-1B69-4298-8D13-91716DEC7442.pdf" purpose="source"}
