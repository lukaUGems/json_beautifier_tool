#!/bin/bash
set -e
cd "$(dirname "$0")"

APP_NAME="JSON Viewer"
APP_DIR="build/${APP_NAME}.app"
DMG_NAME="JSON Viewer.dmg"
STAGE="build/dmg-stage"

# 1. Clean release build of the app
./build.sh

# 2. Stage a folder with the app + a shortcut to /Applications
echo "Staging DMG contents..."
rm -rf "${STAGE}" "build/${DMG_NAME}"
mkdir -p "${STAGE}"
cp -R "${APP_DIR}" "${STAGE}/"
ln -s /Applications "${STAGE}/Applications"

# 3. Build a compressed DMG
echo "Building DMG..."
hdiutil create \
  -volname "${APP_NAME}" \
  -srcfolder "${STAGE}" \
  -ov -format UDZO \
  "build/${DMG_NAME}"

rm -rf "${STAGE}"
echo ""
echo "Done: build/${DMG_NAME}"
