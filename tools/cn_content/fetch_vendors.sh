#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VENDOR="$ROOT/vendor"
mkdir -p "$VENDOR"

clone_or_pull() {
  local url="$1"
  local dir="$2"
  if [[ -d "$dir/.git" ]]; then
    git -C "$dir" pull --ff-only || true
  else
    git clone --depth 1 "$url" "$dir"
  fi
}

clone_or_pull "https://github.com/pwxcoo/chinese-xinhua.git" "$VENDOR/chinese-xinhua"
clone_or_pull "https://github.com/chinese-poetry/chinese-poetry.git" "$VENDOR/chinese-poetry"

echo "Vendors ready under $VENDOR"
echo "Note: chinese-dictionary (Gitee) — clone manually if needed:"
echo "  git clone --depth 1 https://gitee.com/ridp/chinese-dictionary.git $VENDOR/chinese-dictionary"
