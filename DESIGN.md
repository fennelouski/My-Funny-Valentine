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


## October 4 creative-card upgrade, prepared for native verification

The owner asked for richer cards, playful opening, email/print/PDF/GIF/chat sharing, and current Apple/ChatGPT options. This refinement keeps the existing burgundy/pink app identity, thirty starter IDs, six original illustrations and saved local card graph. It does not replace or migrate the already submitted releases.

New starter drafts pair the existing messages with six visual families: comic bursts, cosmic orbits, a love-letter envelope, photo-booth prints, confetti and layered pop-up hearts. Five layout variants per family change print geometry, framing or ornament placement. Original saved cards keep the classic renderer until their owner chooses a new style. The new optional composition lives inside the existing layout JSON; missing or unknown compositions preserve the old layout.

The card is the main object. Tap Open card or drag across it to reveal the inside. A local clock moves the appropriate printed ornaments; explicit motion-off and Reduce Motion keep the preview calm. Text and personal-photo controls precede style options, so the editor starts with the person's words. Family buttons carry their actual palette, named typeface and a selected checkmark. All labels wrap and controls retain native accessibility/keyboard behavior.

An immutable snapshot copies the current text, layout and image bytes before sharing. One CoreGraphics drawing path produces the preview, opening GIF frames, front PNG, transparent PNG chat image and printable front. The 4×6-inch PDF puts the full message on readable inside pages and continues longer notes. The browser file embeds native frames and escaped complete text, uses a keyboard-accessible open button, and has no CDN or remote script. The native print and share choosers leave destinations and sending to the user. A PNG chat image is not a registered Messages sticker pack.

Apple's interactive Image Playground stays optional and system-managed. The existing SDK supports source photos and illustration/animation/sketch styles; on 26.0+ the sheet also permits Apple's external-provider style. Apple's sheet handles its provider setup and consent. The app does not claim its own Sign in with ChatGPT connection. The installed 26.5 SDK lacks the new closest-size and hinge APIs. Manual opening works on existing platforms; actual iPhone Duo hinge effects need the documented 27.1 beta SDK and device checks before they can ship.

Evidence: [Apple's interactive Image Playground APIs](https://developer.apple.com/videos/play/wwdc2026/375/), [ImageCreator discontinuation](https://developer.apple.com/news/?id=dz9wvq0r), [iPhone Duo tools](https://developer.apple.com/iphone-duo/), [hinge effects and layout separation](https://developer.apple.com/videos/play/tech-talks/111464/), [ChatGPT preview capability limits](https://developers.openai.com/siwc/token-sharing-open-source/preview-limitations).

Seven new deterministic compatibility/render/export tests are prepared. No compiler, device, print job or provider request has run for this candidate. Root owns the bounded native checks and final visual approval. Future checks must verify actual print/share chooser behavior, full large-text reflow, narrow Mac windows, rendering budgets and consent flow before any updated release claim.

Private DEBUG verification uses a valid UUID preference suite and temporary card/media directories. Unit and rejected-session hosts stop before creating a model container or app view. The three prepared UI methods use the genuine local editor and export controls, while provider, Photos and print actions are unavailable. Release keeps its original storage paths and service availability. Six guard tests are prepared; none of these new tests has run yet.
