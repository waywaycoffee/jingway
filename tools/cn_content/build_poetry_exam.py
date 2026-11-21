#!/usr/bin/env python3
"""Merge curated poetry ids into grade-tagged exam_core.json.

If vendor/chinese-poetry is missing, keeps the seed file already in-repo.
"""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SEED = ROOT / "apps/mobile/assets/jingway/poetry/exam_core.json"
OUT_MOBILE = SEED
OUT_API = ROOT / "services/api/data/poetry/exam_core.json"


def main() -> None:
    data = json.loads(SEED.read_text(encoding="utf-8"))
    # Placeholder for future vendor merge; seed is already grade-tagged.
    OUT_MOBILE.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    OUT_API.parent.mkdir(parents=True, exist_ok=True)
    OUT_API.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"wrote {OUT_MOBILE} ({len(data.get('items', []))} items)")


if __name__ == "__main__":
    main()
