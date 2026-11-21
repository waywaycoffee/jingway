#!/usr/bin/env bash
# Fetch MIT content vendors. Prefer gh authenticated download when git clone
# to GitHub is unstable (common on some networks).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VENDOR="$ROOT/vendor"
mkdir -p "$VENDOR"

fetch_xinhua_via_gh() {
  local dest="$VENDOR/chinese-xinhua"
  mkdir -p "$dest/data"
  if ! command -v gh >/dev/null 2>&1; then
    echo "gh CLI required for authenticated fetch" >&2
    return 1
  fi
  TOKEN="$(gh auth token)"
  gh api repos/pwxcoo/chinese-xinhua/contents/LICENSE -H "Accept: application/vnd.github.raw" >"$dest/LICENSE"
  gh api repos/pwxcoo/chinese-xinhua/contents/README.md -H "Accept: application/vnd.github.raw" >"$dest/README.md"
  local f
  for f in xiehouyu.json idiom.json word.json ci.json; do
    echo "downloading chinese-xinhua/data/$f ..."
    curl -fL --http1.1 --retry 8 --retry-all-errors --retry-delay 2 \
      --connect-timeout 30 --max-time 900 \
      -H "Authorization: Bearer $TOKEN" \
      -o "$dest/data/$f" \
      "https://raw.githubusercontent.com/pwxcoo/chinese-xinhua/master/data/$f"
  done
  echo "chinese-xinhua ready at $dest"
}

fetch_poetry_subset_via_gh() {
  local dest="$VENDOR/chinese-poetry"
  mkdir -p "$dest"
  # Lightweight curated files instead of full 54k-star monorepo clone.
  local paths=(
    "README.md"
    "json/唐诗三百首.json"
  )
  # Fallbacks if path layout differs across branches/tags.
  TOKEN="$(gh auth token)"
  if gh api repos/chinese-poetry/chinese-poetry/contents/README.md -H "Accept: application/vnd.github.raw" >"$dest/README.md"; then
    echo "poetry README ok"
  fi
  # Discover a compact tang poetry JSON path
  local candidate
  for candidate in \
    "json/唐诗三百首.json" \
    "全唐诗/唐诗三百首.json" \
    "唐诗/唐诗三百首.json"
  do
    echo "try poetry $candidate"
    if curl -fL --http1.1 --retry 5 --retry-all-errors --retry-delay 2 \
      --connect-timeout 20 --max-time 300 \
      -H "Authorization: Bearer $TOKEN" \
      -o "$dest/tang300.json" \
      "https://raw.githubusercontent.com/chinese-poetry/chinese-poetry/master/$candidate"; then
      echo "poetry subset saved as $dest/tang300.json"
      return 0
    fi
  done
  echo "poetry subset not found via known paths; listing repo for manual pick" >&2
  gh api repos/chinese-poetry/chinese-poetry/git/trees/master?recursive=1 \
    --jq '.tree[].path' | rg -i "唐诗三百首|poet.tang|tang" | head -40 || true
  return 1
}

# Prefer gh path; fall back to shallow clone.
if [[ ! -f "$VENDOR/chinese-xinhua/data/word.json" ]]; then
  fetch_xinhua_via_gh || {
    echo "gh fetch failed; trying git clone..."
    git clone --depth 1 https://github.com/pwxcoo/chinese-xinhua.git "$VENDOR/chinese-xinhua"
  }
else
  echo "chinese-xinhua already present"
fi

if [[ ! -f "$VENDOR/chinese-poetry/tang300.json" && ! -d "$VENDOR/chinese-poetry/.git" ]]; then
  fetch_poetry_subset_via_gh || echo "poetry subset skipped (network/path); seed exam_core.json still usable"
else
  echo "chinese-poetry already present"
fi

echo "Vendors under $VENDOR"
echo "Note: chinese-dictionary (Gitee) — clone manually if needed:"
echo "  git clone --depth 1 https://gitee.com/ridp/chinese-dictionary.git $VENDOR/chinese-dictionary"
