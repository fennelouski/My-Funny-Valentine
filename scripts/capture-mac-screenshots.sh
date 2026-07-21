#!/bin/bash
#
# Captures macOS App Store screenshots from a DEBUG build.
#
#   scripts/capture-mac-screenshots.sh /path/to/My\ Funny\ Valentine.app
#
# Launches the app on each tab (Home / My Cards / Settings), captures its
# window without the shadow, and writes exact 1280x800 PNGs into
# app-store/screenshots/mac/.
#
set -euo pipefail

APP="${1:?usage: $0 /path/to/My_Funny_Valentine.app}"
OUT="app-store/screenshots/mac"
mkdir -p "$OUT"

BUNDLE_ID="com.nathanfennel.My-Funny-Valentine"

window_id() {
  # Front window ID of the app, via CGWindowList.
  swift - <<'EOF'
import CoreGraphics
let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as! [[String: Any]]
for w in list {
    if let owner = w[kCGWindowOwnerName as String] as? String,
       owner == "My Funny Valentine",
       let layer = w[kCGWindowLayer as String] as? Int, layer == 0,
       let id = w[kCGWindowNumber as String] as? Int {
        print(id)
        break
    }
}
EOF
}

capture() {
  local tab="$1" name="$2"
  osascript -e "tell application \"My Funny Valentine\" to quit" >/dev/null 2>&1 || true
  sleep 1
  open -a "$APP" --args -screenshotTab "$tab" -seedSampleCards YES -skipOnboarding YES
  sleep 5
  local wid
  wid=$(window_id)
  if [ -z "$wid" ]; then echo "no window for tab $tab"; return 1; fi
  screencapture -o -x -l "$wid" "$OUT/$name.png"
  # Retina capture is 2x; normalize to the exact App Store size.
  sips -z 800 1280 "$OUT/$name.png" >/dev/null
  echo "captured $name ($(sips -g pixelWidth -g pixelHeight "$OUT/$name.png" | tail -2 | tr -d '\n' | sed 's/[a-zA-Z:]//g'))"
}

capture 0 "01-Home"
capture 1 "02-MyCards"
capture 2 "03-Settings"

osascript -e "tell application \"My Funny Valentine\" to quit" >/dev/null 2>&1 || true
echo "done"
