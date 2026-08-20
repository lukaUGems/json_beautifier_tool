#!/bin/bash
set -e
cd "$(dirname "$0")"

APP_NAME="JSON Viewer"
APP_DIR="build/${APP_NAME}.app"
MACOS_DIR="${APP_DIR}/Contents/MacOS"
RES_DIR="${APP_DIR}/Contents/Resources"

echo "Cleaning previous build..."
rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}" "${RES_DIR}"

echo "Compiling Swift..."
swiftc -O main.swift -o "${MACOS_DIR}/JSONViewer" \
  -framework Cocoa -framework WebKit

echo "Copying resources..."
cp Info.plist "${APP_DIR}/Contents/Info.plist"
cp ui.html "${RES_DIR}/ui.html"
cp AppIcon.icns "${RES_DIR}/AppIcon.icns"

echo "Ad-hoc code signing..."
codesign --force --deep --sign - "${APP_DIR}" 2>/dev/null || echo "(codesign skipped)"

echo "Done: ${APP_DIR}"
