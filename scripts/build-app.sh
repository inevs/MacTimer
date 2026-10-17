#!/bin/zsh
# Baut MacTimer.app aus dem Swift Package.
set -euo pipefail

ROOT="${0:A:h:h}"
APP="$ROOT/build/MacTimer.app"

cd "$ROOT"
swift build -c release
BIN_PATH="$(swift build -c release --show-bin-path)"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_PATH/MacTimer" "$APP/Contents/MacOS/MacTimer"
cp "$ROOT/Support/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

# Gong-Datei (gong.mp3/.wav/.m4a/.aiff/.caf) mitkopieren, falls vorhanden
setopt null_glob
gongs=("$ROOT"/Resources/gong.*)
if (( ${#gongs} > 0 )); then
    cp "${gongs[@]}" "$APP/Contents/Resources/"
else
    echo "Hinweis: keine Resources/gong.* gefunden – es wird der Systemsound 'Glass' verwendet."
fi

codesign --force --sign - "$APP"
echo "Fertig: $APP"
