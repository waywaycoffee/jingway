#!/usr/bin/env python3
"""Build a tiny grade-tagged syllabus JSON from chinese-xinhua when present."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
VENDOR = ROOT / "vendor/chinese-xinhua"
OUT = ROOT / "services/api/data/syllabus/cn_g7_sample_chars.json"


def main() -> None:
    words: list[dict] = []
    word_file = VENDOR / "data" / "word.json"
    if word_file.exists():
        raw = json.loads(word_file.read_text(encoding="utf-8"))
        # xinhua formats vary; accept list of {word, ...} or dict.
        items = raw if isinstance(raw, list) else list(raw.values()) if isinstance(raw, dict) else []
        for item in items[:200]:
            if not isinstance(item, dict):
                continue
            w = item.get("word") or item.get("ci") or item.get("name")
            gloss = item.get("explanation") or item.get("desc") or item.get("pinyin") or ""
            if not w:
                continue
            words.append({"word": str(w), "gloss": str(gloss)[:120], "grades": [7]})
    if not words:
        words = [
            {"word": "疑", "gloss": "怀疑；似乎", "grades": [7]},
            {"word": "霜", "gloss": "近地面水汽凝成的白色冰晶", "grades": [7]},
            {"word": "岱宗", "gloss": "泰山的尊称", "grades": [7, 8]},
        ]

    book = {
        "id": "cn_g7_sample_chars",
        "title": "七年级字词听写（样例）",
        "kind": "dictation",
        "grades": [7],
        "source": "chinese-xinhua or seed",
        "words": words,
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(book, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {OUT} ({len(words)} words)")


if __name__ == "__main__":
    main()
