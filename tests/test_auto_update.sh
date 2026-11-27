#!/bin/bash
set -e

PROJECT_DIR="/Volumes/DATA/DEV/MacVietKey/MacVietKey"
BUILD_APP="/Volumes/DATA/DEV/MacVietKey/build_output/MacVietKey.app"
RELEASE_ZIP="$PROJECT_DIR/release/MacVietKey-v2.2.4-macOS.zip"
RELEASE_DMG="$PROJECT_DIR/release/MacVietKey-v2.2.4-macOS.dmg"
RELEASE_ARM_DMG="$PROJECT_DIR/release/MacVietKey-v2.2.4-macOS-arm64.dmg"

echo "==========================================="
echo "RUNNING AUTO-UPDATE & PACKAGING TEST SUITE"
echo "==========================================="

# Test 1: Validate version.json schema & fields
python3 -c "
import json
with open('$PROJECT_DIR/version.json', 'r', encoding='utf-8') as f:
    d = json.load(f)
lv = d['latestVersion']
assert lv['versionName'] == '2.2.4', lv
assert int(lv['versionCode']) == 54, lv
assert lv['downloadZipUrl'].endswith('MacVietKey-v2.2.4-macOS.zip')
assert lv['downloadUrl'].endswith('MacVietKey-v2.2.4-macOS.dmg')
assert lv['downloadUrlArm64'].endswith('MacVietKey-v2.2.4-macOS-arm64.dmg')
print('[PASS] AutoUpdate Case 1: version.json schema and v2.2.4 URLs verified')
"

# Test 2: Verify Universal binary architectures & LC_BUILD_VERSION minos 11.0
lipo -info "$BUILD_APP/Contents/MacOS/MacVietKey" | grep -q "x86_64"
lipo -info "$BUILD_APP/Contents/MacOS/MacVietKey" | grep -q "arm64"
otool -l "$BUILD_APP/Contents/MacOS/MacVietKey" | grep -q "minos 11.0"
echo "[PASS] AutoUpdate Case 2: Universal binary (arm64 + x86_64) & minos 11.0 verified"

# Test 3: Verify Codesign & permanent Designated Requirement
codesign --verify --deep --strict "$BUILD_APP"
codesign -d -r- "$BUILD_APP" 2>&1 | grep -q 'designated => identifier "com.vuahethong.vuaoffice.macvietkey"'
echo "[PASS] AutoUpdate Case 3: Strict codesign & permanent Designated Requirement verified"

# Test 4: Extract release ZIP via ditto and verify extracted bundle integrity
TMP_DIR=$(mktemp -d /tmp/mvk_autoupdate_test.XXXXXX)
trap 'rm -rf "$TMP_DIR"' EXIT
ditto -xk "$RELEASE_ZIP" "$TMP_DIR/extract"
test -x "$TMP_DIR/extract/MacVietKey.app/Contents/MacOS/MacVietKey"
codesign --verify --deep --strict "$TMP_DIR/extract/MacVietKey.app"
VER=$(defaults read "$TMP_DIR/extract/MacVietKey.app/Contents/Info.plist" CFBundleShortVersionString)
BUILD=$(defaults read "$TMP_DIR/extract/MacVietKey.app/Contents/Info.plist" CFBundleVersion)
test "$VER" = "2.2.4"
test "$BUILD" = "54"
echo "[PASS] AutoUpdate Case 4: ditto -xk extracted valid MacVietKey.app v$VER (build $BUILD)"

# Test 5: Simulate full self-replacement updater script (wait PID -> atomic swap -> xattr -cr -> cleanup)
mkdir -p "$TMP_DIR/Applications/MacVietKey.app/Contents/MacOS"
echo '#!/bin/sh
sleep 0.5' > "$TMP_DIR/Applications/MacVietKey.app/Contents/MacOS/MacVietKey"
chmod +x "$TMP_DIR/Applications/MacVietKey.app/Contents/MacOS/MacVietKey"
"$TMP_DIR/Applications/MacVietKey.app/Contents/MacOS/MacVietKey" &
FAKE_PID=$!

# Simulate quarantine attribute on extracted app
xattr -w com.apple.quarantine "0081;65555555;Test;" "$TMP_DIR/extract/MacVietKey.app" 2>/dev/null || true

DST_APP="$TMP_DIR/Applications/MacVietKey.app"
SRC_APP="$TMP_DIR/extract/MacVietKey.app"
BACKUP_APP="$DST_APP.bak.$FAKE_PID"

i=0
while kill -0 "$FAKE_PID" 2>/dev/null && [ $i -lt 20 ]; do sleep 0.1; i=$((i+1)); done
kill -9 "$FAKE_PID" 2>/dev/null || true
if [ -e "$DST_APP" ]; then mv "$DST_APP" "$BACKUP_APP"; fi
mv "$SRC_APP" "$DST_APP"
rm -rf "$BACKUP_APP"
xattr -cr "$DST_APP"

test -x "$DST_APP/Contents/MacOS/MacVietKey"
test ! -e "$BACKUP_APP"
! xattr -p com.apple.quarantine "$DST_APP" >/dev/null 2>&1
codesign --verify --deep --strict "$DST_APP"
NEW_VER=$(defaults read "$DST_APP/Contents/Info.plist" CFBundleShortVersionString)
test "$NEW_VER" = "2.2.4"
echo "[PASS] AutoUpdate Case 5: Atomic self-replacement, quarantine removal & signature check passed"

# Test 6: Verify DMG & ARM64 DMG integrity
hdiutil verify "$RELEASE_DMG" >/dev/null
hdiutil verify "$RELEASE_ARM_DMG" >/dev/null
echo "[PASS] AutoUpdate Case 6: Both Universal DMG and Apple Silicon DMG verified with hdiutil"

echo "==========================================="
echo "ALL 6/6 AUTO-UPDATE TESTS PASSED!"
echo "==========================================="
