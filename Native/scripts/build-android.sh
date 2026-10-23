#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-only
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
: "${JAVA_HOME:?Set JAVA_HOME to a JDK 17 installation}"
: "${ANDROID_HOME:?Set ANDROID_HOME to your Android SDK}"
mkdir -p "$ROOT/build"
export ANDROID_USER_HOME="${ANDROID_USER_HOME:-$ROOT/build/android-user}"
export GRADLE_USER_HOME="${GRADLE_USER_HOME:-$ROOT/build/gradle-home}"
KEY="$ROOT/build/tabbridge-debug.keystore"
if [ ! -f "$KEY" ]; then
  "$JAVA_HOME/bin/keytool" -genkeypair -keystore "$KEY" -alias androiddebugkey \
    -storepass android -keypass android -dname 'CN=TabBridge Development' \
    -keyalg RSA -keysize 2048 -validity 3650
fi
bash "$ROOT/Android/gradlew" -p "$ROOT/Android" assembleDebug --console=plain
