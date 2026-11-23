#!/usr/bin/env bash
# Offline smoke for open-source integration (congcong / Reciter / SuFei / Mogao / CMRC).
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

check "P0 guards" bash "$ROOT/tools/cn_content/verify_p0_accept.sh"
check "comprehensions asset" \
  test -f "$ROOT/apps/mobile/assets/jingway/poetry/comprehensions_core.json"
check "integration doc" \
  test -f "$ROOT/docs/product/OPEN_SOURCE_INTEGRATION.md"
check "poetry cloze domain" \
  test -f "$ROOT/apps/mobile/lib/features/poetry/domain/poetry_cloze.dart"
check "excerpt domain" \
  test -f "$ROOT/apps/mobile/lib/features/jingway/domain/jingway_excerpt.dart"
check "CJK tokenize helper present" \
  grep -q 'u4e00-\\u9fff' \
    "$ROOT/apps/mobile/lib/features/reading/presentation/reading_text_spans.dart"
check "Xinhua lookup wired in reader" \
  grep -q 'showXinhuaLookupSheet' \
    "$ROOT/apps/mobile/lib/features/reading/presentation/reading_reader_screen.dart"
check "g3 story pack id" \
  grep -q 'jingwayG3StoryPracticeId' \
    "$ROOT/apps/mobile/lib/features/jingway/domain/jingway_practice.dart"
check "session report widget" \
  grep -q '_SessionReport' \
    "$ROOT/apps/mobile/lib/features/jingway/presentation/jingway_exam_screen.dart"

if [[ "$fail" -ne 0 ]]; then
  echo "OSS integration guards failed."
  exit 1
fi

echo "== dart analyze (jingway + poetry + reading tokenize) =="
cd "$ROOT/apps/mobile"
set +e
dart analyze \
  lib/features/jingway/ \
  lib/features/poetry/ \
  lib/features/reading/presentation/reading_text_spans.dart \
  lib/features/reading/data/reading_gloss.dart \
  lib/features/reading/data/reading_iplus1.dart \
  lib/features/reading/presentation/reading_reader_screen.dart \
  2>&1 | tee /tmp/jingway_oss_analyze.txt
analyze_rc=${PIPESTATUS[0]}
set -e
if grep -E '^[[:space:]]*error •' /tmp/jingway_oss_analyze.txt >/dev/null; then
  echo "FAIL analyze has errors"
  exit 1
fi
# infos/warnings OK; exit 3 from analyzer is "warnings only"
if [[ "$analyze_rc" -gt 3 ]]; then
  echo "FAIL analyze exit $analyze_rc"
  exit 1
fi
echo "OK  analyze (no errors)"

echo "== flutter test smoke =="
flutter test --no-pub \
  test/features/poetry/poetry_cloze_test.dart \
  test/features/jingway/jingway_integration_smoke_test.dart \
  test/features/jingway/xinhua_dictionary_test.dart \
  test/features/player/cn_dictation_diff_test.dart \
  test/features/reading/reading_gloss_test.dart \
  test/features/reading/reading_novel_reader_test.dart

echo "OSS integration smoke passed."
