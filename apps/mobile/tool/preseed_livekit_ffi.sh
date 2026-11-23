#!/usr/bin/env bash
# Preseed livekit_ffi native libs into hooks_runner shared cache.
# Direct GitHub release downloads often fail in CN networks; use a mirror.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VER="${LIVEKIT_FFI_VERSION:-0.15.0}"
MIRROR_PREFIX="${LIVEKIT_FFI_MIRROR:-https://ghproxy.net/https://github.com}"
BASE="${MIRROR_PREFIX}/livekit/rust-sdks/releases/download/livekit-ffi/v${VER}"
SHARED="${ROOT}/.dart_tool/hooks_runner/shared/livekit_ffi"
# Hook resolves: outputDirectoryShared/livekit_ffi/<triple>/liblivekit_ffi.so
# outputDirectoryShared is typically .../shared/livekit_ffi/
DEST_ROOT="${SHARED}/livekit_ffi"

# Android ABIs the Flutter/Android hook may request (app abiFilters may be arm64-only).
TRIPLES=(
  aarch64-linux-android
  armv7-linux-androideabi
  x86_64-linux-android
)

mkdir -p "$DEST_ROOT"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

download_one() {
  local triple="$1"
  local zip_url="${BASE}/build-${triple}.zip"
  local out_dir="${DEST_ROOT}/${triple}"
  local so="${out_dir}/liblivekit_ffi.so"
  if [[ -f "$so" && -s "$so" ]]; then
    echo "skip existing ${triple}"
    return 0
  fi
  echo "download ${triple}"
  curl -fsSL --retry 5 --retry-delay 2 -o "${TMP}/${triple}.zip" "$zip_url"
  mkdir -p "$out_dir"
  unzip -qo "${TMP}/${triple}.zip" -d "$out_dir"
  if [[ ! -f "$so" ]]; then
    # Zip may nest the .so; flatten if needed.
    local found
    found="$(find "$out_dir" -name 'liblivekit_ffi.so' -type f | head -1 || true)"
    if [[ -n "$found" && "$found" != "$so" ]]; then
      mv "$found" "$so"
    fi
  fi
  [[ -f "$so" && -s "$so" ]] || {
    echo "missing liblivekit_ffi.so for ${triple}" >&2
    return 1
  }
  # Also mirror under build/ for older hook layouts.
  mkdir -p "${SHARED}/build/livekit_ffi/${triple}"
  cp -f "$so" "${SHARED}/build/livekit_ffi/${triple}/liblivekit_ffi.so"
}

# Prefer ghproxy; fall back to ghfast if a download fails.
for triple in "${TRIPLES[@]}"; do
  if ! download_one "$triple"; then
    echo "retry via ghfast.top for ${triple}"
    MIRROR_PREFIX="https://ghfast.top/https://github.com"
    BASE="${MIRROR_PREFIX}/livekit/rust-sdks/releases/download/livekit-ffi/v${VER}"
    download_one "$triple"
  fi
done

# Optional: patch pub-cache hook download base to the same mirror (local only).
HOOK="${HOME}/.pub-cache/hosted/pub.flutter-io.cn/livekit_ffi-${VER}/hook/build.dart"
if [[ -f "$HOOK" ]] && ! grep -q 'ghproxy.net\|ghfast.top' "$HOOK"; then
  cp -f "$HOOK" "${HOOK}.bak"
  sed -i '' \
    "s|https://github.com/livekit/rust-sdks/releases/download/livekit-ffi|${MIRROR_PREFIX}/livekit/rust-sdks/releases/download/livekit-ffi|g" \
    "$HOOK"
  echo "patched hook mirror: $HOOK"
fi

echo "livekit_ffi ${VER} preseeded under ${DEST_ROOT}"
