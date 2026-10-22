#!/bin/sh
# Builds a universal (Apple silicon + Intel) build/Soundboard.app.
#
#   ./build.sh                       ad hoc signed, for local use
#   SIGN_IDENTITY="Developer ID Application: ..." ./build.sh
#                                    hardened runtime signature, ready for notarization
#   VERSION=1.2.0 ./build.sh         stamps the version into Info.plist
set -e
cd "$(dirname "$0")"

ARCHS="--arch arm64 --arch x86_64"
swift build -c release $ARCHS
BIN="$(swift build -c release $ARCHS --show-bin-path)/Soundboard"

APP=build/Soundboard.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN" "$APP/Contents/MacOS/"
cp Info.plist "$APP/Contents/"

if [ -n "$VERSION" ]; then
  plutil -replace CFBundleShortVersionString -string "$VERSION" "$APP/Contents/Info.plist"
fi

if [ -n "$SIGN_IDENTITY" ]; then
  codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP"
else
  codesign --force --sign - "$APP"
fi

echo "Built $APP"
