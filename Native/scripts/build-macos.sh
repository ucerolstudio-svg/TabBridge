#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-only
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DEST="${1:-$ROOT/build/Build/Products/Debug}"
SDK="${TABBRIDGE_SDK:-/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk}"
BUILD="$ROOT/build/TabBridge"
APP="$DEST/TabBridge.app"
mkdir -p "$BUILD" "$APP/Contents/MacOS" "$APP/Contents/Resources"
SOURCES=()
for source in "$ROOT"/Mac/*.swift; do
  case "$source" in */OpenSidecarMacApp.swift|*/CheckForUpdatesView.swift) continue;; esac
  SOURCES+=("$source")
done
xcrun swiftc -sdk "$SDK" -target "$(uname -m)-apple-macosx14.0" -swift-version 5 -O \
  -D TABBRIDGE_HOST -import-objc-header "$ROOT/Mac/OpenSidecarMac-Bridging-Header.h" \
  -framework AppKit -framework SwiftUI -framework ScreenCaptureKit -framework VideoToolbox \
  -framework Network -framework CoreMedia -framework CoreGraphics -framework WidgetKit \
  "${SOURCES[@]}" "$ROOT/Shared/Protocol.swift" "$ROOT/Shared/DirectCable.swift" "$ROOT/Shared/LogSnapshot.swift" "$ROOT/Shared/AppStore.swift" \
  "$ROOT"/Native/Core/*.swift "$ROOT"/Native/App/*.swift -o "$APP/Contents/MacOS/TabBridge"
cp "$ROOT/Native/App/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/LICENSE" "$APP/Contents/Resources/"
if [ -n "${TABBRIDGE_ADB_DIR:-}" ]; then
  mkdir -p "$APP/Contents/Resources/Tools"
  cp "$TABBRIDGE_ADB_DIR/adb" "$APP/Contents/Resources/Tools/adb"
  cp "$TABBRIDGE_ADB_DIR/NOTICE.txt" "$APP/Contents/Resources/Tools/NOTICE.txt"
  if [ -d "$TABBRIDGE_ADB_DIR/lib64" ]; then ditto "$TABBRIDGE_ADB_DIR/lib64" "$APP/Contents/Resources/Tools/lib64"; fi
fi
if [ -f "$ROOT/Android/app/build/outputs/apk/debug/app-debug.apk" ]; then
  cp "$ROOT/Android/app/build/outputs/apk/debug/app-debug.apk" "$APP/Contents/Resources/TabBridge-Android.apk"
fi
cp "$ROOT/Native/THIRD_PARTY_NOTICES.md" "$APP/Contents/Resources/"
EXT="$APP/Contents/PlugIns/TabBridgeWidget.appex"
mkdir -p "$EXT/Contents/MacOS"
xcrun swiftc -sdk "$SDK" -target "$(uname -m)-apple-macosx14.0" -swift-version 5 -O \
  -application-extension -parse-as-library -framework SwiftUI -framework WidgetKit -framework Foundation \
  -Xlinker -e -Xlinker _NSExtensionMain "$ROOT"/Native/Core/*.swift "$ROOT/Native/Widget/TabWidget.swift" \
  -o "$EXT/Contents/MacOS/TabBridgeWidget"
cp "$ROOT/Native/Widget/Info.plist" "$EXT/Contents/Info.plist"
codesign --force --sign - --requirements '=designated => identifier "dev.tabbridge.mac.widget"' --entitlements "$ROOT/Native/Widget/Entitlements.plist" "$EXT"
codesign --force --sign - --requirements '=designated => identifier "dev.tabbridge.mac"' "$APP"
codesign --verify --deep --strict "$APP"
echo "Built: $APP"
