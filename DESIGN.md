# My Funny Valentine native design decisions

## Basis

The working brief is inferred from the app's greeting-card purpose and the owner's request to finish and release the apps. These are implementation decisions, not attributed feedback on this app. The native interface was built directly with written decisions; no mockup review is recorded.

## Start with a finished card

Show 30 illustrated, editable starters on the first screen. Each of the six art worlds has five short sayings. Complete artwork and optional photos let a person choose a card before importing anything. A starter opens a detached draft and enters the library only after Save.

Interleave the six collections in the first rows so people see the artwork's variety immediately, with the first pizza card still leading. Each collection keeps its five sayings.

## Let the card carry the personality

Use the six original illustrations for the app's character. Keep the surrounding interface in native grouped colors with a burgundy and pink accent. Large bold headings identify the current task. The card's pale message area supports readable black text across pizza, space, birds, dinosaur, disco and sweets artwork.

## Edit beside the result

Keep one 2:3 card preview and one clear set of message, note, photo and face controls. Wide layouts separate the preview and editor; compact layouts scroll vertically. Labels wrap, fields allow multiple lines and actions keep comfortable native targets. Existing longer messages must remain editable.

## Preserve the user's work

Save commits a detached draft; Cancel leaves the saved graph alone. The same renderer drives previews, PNG sharing and GIF frames. The face animation moves only the added face. Photos are optional, foreground masking has a crop fallback, and failed imports or exports keep the draft.

Cards and photos are saved on this device using the existing local disk schema and store location. Sharing sends an exported copy. A storage-open failure shows a retry screen rather than an editable memory-only library. Storage settings state where cards are saved.

## Make optional generation honest

Built-in suggestions remain usable without Apple Intelligence. Show Image Playground only when the system supports it. Its Apple-managed processing and limits are separate from offline starter cards and local face detection. Keep platform availability checks in the native implementation.

## Verify the finished interface

Native checks for large text, appearances, narrow windows, keyboard behavior, photo results and face animation remain pending. Final App Store images will use fresh native captures, ten per platform, with short centered copy, varied backgrounds, a centered upright hero and outward fans where supporting captures are used.
