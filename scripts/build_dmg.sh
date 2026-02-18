#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────────
# Kimai Desktop macOS — Build DMG Script
# ─────────────────────────────────────────────

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_FILE="$PROJECT_DIR/kimai_desktop_macos.xcodeproj"
SCHEME="kimai_desktop_macos"
APP_NAME="Kimai Desktop"
BUNDLE_NAME="kimai_desktop_macos"
BUILD_DIR="$PROJECT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/${BUNDLE_NAME}.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
DMG_DIR="$BUILD_DIR/dmg_content"
DMG_OUTPUT="$BUILD_DIR/${APP_NAME// /_}.dmg"
CONFIGURATION="Release"

# ─────────────────────────────────────────────
# Colors
# ─────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

step() { echo -e "\n${BLUE}▸ $1${NC}"; }
success() { echo -e "${GREEN}✓ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
fail() { echo -e "${RED}✗ $1${NC}"; exit 1; }

# ─────────────────────────────────────────────
# Check prerequisites
# ─────────────────────────────────────────────
step "Checking prerequisites..."

XCODEBUILD="/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild"
if [ ! -f "$XCODEBUILD" ]; then
    XCODEBUILD=$(which xcodebuild 2>/dev/null || true)
    if [ -z "$XCODEBUILD" ]; then
        fail "xcodebuild not found. Install Xcode from the App Store."
    fi
fi
success "xcodebuild found: $XCODEBUILD"

if ! command -v hdiutil &>/dev/null; then
    fail "hdiutil not found (should be included with macOS)."
fi
success "hdiutil found"

# ─────────────────────────────────────────────
# Clean previous build
# ─────────────────────────────────────────────
step "Cleaning previous build artifacts..."
rm -rf "$ARCHIVE_PATH" "$EXPORT_DIR" "$DMG_DIR" "$DMG_OUTPUT"
mkdir -p "$BUILD_DIR"
success "Clean complete"

# ─────────────────────────────────────────────
# Archive
# ─────────────────────────────────────────────
step "Archiving project (Release)..."
"$XCODEBUILD" archive \
    -project "$PROJECT_FILE" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -archivePath "$ARCHIVE_PATH" \
    -quiet \
    || fail "Archive failed. Check build errors above."
success "Archive created: $ARCHIVE_PATH"

# ─────────────────────────────────────────────
# Extract .app from archive
# ─────────────────────────────────────────────
step "Extracting .app from archive..."
APP_PATH="$ARCHIVE_PATH/Products/Applications/${BUNDLE_NAME}.app"

if [ ! -d "$APP_PATH" ]; then
    # Try finding the .app in the archive
    APP_PATH=$(find "$ARCHIVE_PATH/Products" -name "*.app" -maxdepth 3 | head -1)
    if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
        fail "Could not find .app in archive. Contents:"
    fi
fi

mkdir -p "$EXPORT_DIR"
cp -R "$APP_PATH" "$EXPORT_DIR/"
EXPORTED_APP="$EXPORT_DIR/$(basename "$APP_PATH")"
success "Extracted: $EXPORTED_APP"

# ─────────────────────────────────────────────
# Get version from Info.plist
# ─────────────────────────────────────────────
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$EXPORTED_APP/Contents/Info.plist" 2>/dev/null || echo "1.0")
BUILD=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$EXPORTED_APP/Contents/Info.plist" 2>/dev/null || echo "1")
DMG_OUTPUT="$BUILD_DIR/${APP_NAME// /_}_v${VERSION}_${BUILD}.dmg"
success "Version: $VERSION ($BUILD)"

# ─────────────────────────────────────────────
# Create DMG content
# ─────────────────────────────────────────────
step "Preparing DMG content..."
rm -rf "$DMG_DIR"
mkdir -p "$DMG_DIR"
cp -R "$EXPORTED_APP" "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"
success "DMG content ready (app + Applications symlink)"

# ─────────────────────────────────────────────
# Create DMG
# ─────────────────────────────────────────────
step "Creating DMG..."
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov \
    -format UDZO \
    "$DMG_OUTPUT" \
    || fail "DMG creation failed."
success "DMG created: $DMG_OUTPUT"

# ─────────────────────────────────────────────
# Cleanup
# ─────────────────────────────────────────────
step "Cleaning up temporary files..."
rm -rf "$DMG_DIR" "$ARCHIVE_PATH" "$EXPORT_DIR"
success "Cleanup complete"

# ─────────────────────────────────────────────
# Done
# ─────────────────────────────────────────────
DMG_SIZE=$(du -h "$DMG_OUTPUT" | cut -f1 | xargs)
echo ""
echo -e "${GREEN}════════════════════════════════════════════${NC}"
echo -e "${GREEN}  DMG ready!${NC}"
echo -e "${GREEN}  File: $DMG_OUTPUT${NC}"
echo -e "${GREEN}  Size: $DMG_SIZE${NC}"
echo -e "${GREEN}  Version: $VERSION ($BUILD)${NC}"
echo -e "${GREEN}════════════════════════════════════════════${NC}"
echo ""
