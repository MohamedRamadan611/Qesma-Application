#!/usr/bin/env bash
# FL9: inspects a RELEASE apk and fails if it carries anything that must never ship.
#   bash mobile/tool/check_release_artifact.sh [path-to-apk]
# Checks: signed with a non-debug key, INTERNET is the only permission asked for, no cleartext/emulator host or dev-only
# strings (fake sign-in token, component catalogue route, debug sign-in label), not debuggable, no key material inside.
# Needs the Android SDK build-tools (aapt, apksigner): ANDROID_HOME or D:/Android/Sdk.
set -u
APK="${1:-mobile/build/app/outputs/flutter-apk/app-release.apk}"
SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-/d/Android/Sdk}}"
BT="$(ls -d "$SDK"/build-tools/* 2>/dev/null | sort -V | tail -1)"
fail=0
bad() { echo "FAIL: $*"; fail=1; }
ok() { echo "ok:   $*"; }

[ -f "$APK" ] || { echo "no such apk: $APK"; exit 2; }
[ -d "$BT" ] || { echo "no build-tools under $SDK"; exit 2; }

# 1. signature
CERTS="$("$BT/apksigner.bat" verify --print-certs "$APK" 2>&1)"
if echo "$CERTS" | grep -q "^Signer #1 certificate DN"; then
  if echo "$CERTS" | grep -qi "Android Debug"; then bad "signed with the DEBUG key"; else ok "signed with a non-debug key"; fi
  echo "$CERTS" | grep -E "SHA-(1|256) digest" | sed 's/^/      /'
else
  bad "signature does not verify: $CERTS"
fi

# 2. permissions: INTERNET only (androidx adds its own DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION, which is not a user permission)
PERMS="$("$BT/aapt.exe" dump permissions "$APK" 2>&1 | grep -E "^uses-permission" | sed -E "s/.*name='([^']+)'.*/\1/" | grep -v "DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION" | sort -u)"
if [ "$PERMS" = "android.permission.INTERNET" ]; then ok "only INTERNET is requested"; else bad "unexpected permissions: $(echo $PERMS)"; fi

# 3. manifest flags
BADGING="$("$BT/aapt.exe" dump xmltree "$APK" AndroidManifest.xml 2>&1)"
echo "$BADGING" | grep -q "debuggable.*=(type 0x12)0xffffffff" && bad "android:debuggable is true" || ok "not debuggable"
echo "$BADGING" | grep -q "usesCleartextTraffic.*0xffffffff" && bad "usesCleartextTraffic is true" || ok "no cleartext opt-in"
echo "$BADGING" | grep -q "networkSecurityConfig" && bad "a networkSecurityConfig is present (debug-only file leaked into release)" || ok "no networkSecurityConfig"

# 4. strings that must not be in the artifact
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
unzip -q -o "$APK" -d "$TMP"
for needle in "10.0.2.2" "/_catalog" "fake:" "Debug sign-in" "INITIAL_ROUTE" "BEGIN PRIVATE KEY" "storePassword"; do
  if grep -rUal -- "$needle" "$TMP" >/dev/null 2>&1; then
    bad "found \"$needle\" in: $(grep -rUal -- "$needle" "$TMP" | sed "s|$TMP/||" | head -3 | tr '\n' ' ')"
  else
    ok "no \"$needle\""
  fi
done

# 5. the API base URL baked in must be https
if grep -rUaoE "http://[A-Za-z0-9._-]+(:[0-9]+)?/api" "$TMP/lib" "$TMP/assets" >/dev/null 2>&1; then bad "an http:// API URL is compiled in"; else ok "no http:// API URL compiled in"; fi

[ $fail -eq 0 ] && echo "RELEASE ARTIFACT OK" || echo "RELEASE ARTIFACT REJECTED"
exit $fail
