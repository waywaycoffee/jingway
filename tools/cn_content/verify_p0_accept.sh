#!/usr/bin/env bash
# Offline P0 acceptance guards (no device / no livekit download required).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
fail=0

check() {
  local name="$1"
  shift
  if "$@"; then
    echo "OK  $name"
  else
    echo "FAIL $name"
    fail=1
  fi
}

check "ATTRIBUTION has MIT sources" \
  grep -q 'chinese-xinhua' "$ROOT/docs/ATTRIBUTION.md"
check "ATTRIBUTION marks research-only" \
  grep -q 'NCR' "$ROOT/docs/ATTRIBUTION.md"
check "RESEARCH_CONTENT doc exists" \
  test -f "$ROOT/docs/RESEARCH_CONTENT.md"
check "pubspec has no research assets" \
  bash -c "! grep -E 'data/research|research/ncr|cknow_edit' '$ROOT/apps/mobile/pubspec.yaml'"
check "poetry exam pack exists" \
  test -f "$ROOT/apps/mobile/assets/jingway/poetry/exam_core.json"
check "xinhua seed exists" \
  test -f "$ROOT/apps/mobile/assets/jingway/dict/xinhua_seed.json"
check "g7 syllabus exists" \
  test -f "$ROOT/apps/mobile/assets/syllabus/cn_g7_dictation.json"
check "research gate source exists" \
  test -f "$ROOT/apps/mobile/lib/features/jingway/domain/research_content_gate.dart"
check "research lab screen exists" \
  test -f "$ROOT/apps/mobile/lib/features/jingway/presentation/research_lab_screen.dart"
check "research schemas committed" \
  test -f "$ROOT/data/research/schemas/ncr_item.schema.json"
check "poetry grades field present" \
  grep -q '"grades"' "$ROOT/apps/mobile/assets/jingway/poetry/exam_core.json"
check "applicationId jingway" \
  grep -q 'applicationId = "com.jingway.chinese"' \
    "$ROOT/apps/mobile/android/app/build.gradle.kts"

if [[ "$fail" -ne 0 ]]; then
  echo "P0 acceptance guards failed."
  exit 1
fi
echo "P0 acceptance guards passed."
