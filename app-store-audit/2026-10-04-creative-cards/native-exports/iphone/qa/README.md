# Actual native editor export review

Build 1.0(3), root-r6 candidate. The six source files are byte-identical to `export-artifacts.json`; all hashes/lengths were independently checked before and after this review. No source artifact was modified. Derived previews here use ffmpeg’s actual frames 0/15/29 and Poppler’s full PDF pages at150dpi.

## Actual format and text checks

- Front and inside PNG:800×1200. Their short fixture messages are complete, upright and readable.
- Chat sticker PNG:618×618,27319bytes, genuine alpha range0…255 and transparent pixels. It is a shared image, not a registered sticker pack.
- GIF:30 decoded frames,400×600,100ms each,3seconds total, infinite loop. Reviewed first/middle/last actual frames show front/complete note/front.
- PDF:two full288×432-point pages (4×6inches), viewed entirely after150dpi rendering. The front phrase and inside note are complete in extracted text and visible full pages.
- HTML source:16 embedded400×600 native frames, full front/inside text and Read the message disclosure, restrictive CSP, no external resources/URLs/network calls. Actual browser interaction is not part of this review; escaping of malicious input is supported by source/unit tests, not this plain-text fixture.

## Actual visual defect

The love-letter front crops off the birds’ head/eye tops. The same visible loss appears in the front PNG, GIF frames0/29 and PDF page1. This is actual exported-pixel evidence, not an inferred source risk. Root was notified; the initial review remains unapproved for that artwork. The prior dino/disco-only proposed correction would not repair this birds source.

Inside text, sticker wording and PDF page2 show no material defect in this fixture. The review does not establish image preservation for arbitrary-length old saved notes or all30layouts. No authoring, native/compiler/device action, print/send/provider request or browser interaction occurred.
