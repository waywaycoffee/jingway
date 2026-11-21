#!/usr/bin/env python3
"""Build grade-tagged CN syllabus + offline xinhua pack from vendor when present.

Outputs (committed; vendor/ stays gitignored):
  - apps/mobile/assets/jingway/dict/xinhua_seed.json
  - apps/mobile/assets/syllabus/cn_g7_dictation.json
  - apps/mobile/assets/syllabus/cn_g8_dictation.json
  - apps/mobile/assets/syllabus/cn_idioms_core.json
  - services/api/data/syllabus/cn_*.json
"""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
VENDOR = ROOT / "vendor/chinese-xinhua"
POETRY = ROOT / "apps/mobile/assets/jingway/poetry/exam_core.json"
DICT_OUT = ROOT / "apps/mobile/assets/jingway/dict/xinhua_seed.json"
SYLLABUS_MOBILE = ROOT / "apps/mobile/assets/syllabus"
SYLLABUS_API = ROOT / "services/api/data/syllabus"

# Exam-facing idioms (MIT chinese-xinhua lookup when vendor present).
CURATED_IDIOMS = [
    "一心一意",
    "三心二意",
    "守株待兔",
    "亡羊补牢",
    "画蛇添足",
    "狐假虎威",
    "井底之蛙",
    "对牛弹琴",
    "刻舟求剑",
    "掩耳盗铃",
    "滥竽充数",
    "自相矛盾",
    "叶公好龙",
    "杯弓蛇影",
    "囫囵吞枣",
    "温故知新",
    "举一反三",
    "精益求精",
    "持之以恒",
    "水滴石穿",
    "一览众山小",
    "有朋自远方来",
]

# Extra single characters commonly tested beyond poetry extraction.
CURATED_CHARS = list("疑霜岱宗凌绝顶望月故乡春晓鹳雀楼黄河欲穷千里")


def _clean_gloss(text: str, limit: int = 80) -> str:
    s = re.sub(r"\s+", " ", (text or "").replace("\n", " ")).strip()
    s = re.sub(r"[〈〈].*?[〉〉]", "", s)
    if len(s) > limit:
        s = s[: limit - 1].rstrip() + "…"
    return s


def _load_list(path: Path) -> list[dict]:
    if not path.exists():
        return []
    raw = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(raw, list):
        return [x for x in raw if isinstance(x, dict)]
    if isinstance(raw, dict):
        return [v for v in raw.values() if isinstance(v, dict)]
    return []


def _index_by_word(items: list[dict]) -> dict[str, dict]:
    out: dict[str, dict] = {}
    for item in items:
        w = item.get("word") or item.get("ci") or item.get("name")
        if not w:
            continue
        out[str(w)] = item
    return out


def _chars_from_poetry() -> set[str]:
    chars: set[str] = set()
    if not POETRY.exists():
        return chars
    data = json.loads(POETRY.read_text(encoding="utf-8"))
    for item in data.get("items", []):
        for line in item.get("lines", []):
            for ch in str(line):
                if "\u4e00" <= ch <= "\u9fff":
                    chars.add(ch)
    for ch in CURATED_CHARS:
        if "\u4e00" <= ch <= "\u9fff":
            chars.add(ch)
    return chars


def _entry_from_word(item: dict, fallback_term: str) -> dict:
    pinyin = str(item.get("pinyin") or "").strip()
    gloss = _clean_gloss(
        str(item.get("explanation") or item.get("desc") or item.get("gloss") or "")
    )
    radical = str(item.get("radicals") or item.get("radical") or "").strip()
    strokes_raw = item.get("strokes") or item.get("stroke") or 0
    try:
        strokes = int(str(strokes_raw).strip() or 0)
    except ValueError:
        strokes = 0
    return {
        "pinyin": pinyin,
        "gloss": gloss or fallback_term,
        "radical": radical,
        "strokes": strokes,
    }


def build_dict_pack(word_idx: dict[str, dict], idiom_idx: dict[str, dict]) -> dict:
    chars = sorted(_chars_from_poetry())
    entries: dict[str, dict] = {}
    for ch in chars:
        item = word_idx.get(ch)
        if item:
            entries[ch] = _entry_from_word(item, ch)
        else:
            # Keep a minimal stub so poetry tap-to-lookup still resolves.
            entries[ch] = {
                "pinyin": "",
                "gloss": "（离线释义待补）",
                "radical": "",
                "strokes": 0,
            }

    idioms: dict[str, dict] = {}
    for idiom in CURATED_IDIOMS:
        item = idiom_idx.get(idiom)
        if item:
            idioms[idiom] = {
                "pinyin": str(item.get("pinyin") or "").strip(),
                "gloss": _clean_gloss(
                    str(item.get("explanation") or item.get("desc") or ""), 100
                ),
            }
        else:
            # Seed fallbacks for the two poetry-linked phrases.
            if idiom == "一览众山小":
                idioms[idiom] = {
                    "pinyin": "yī lǎn zhòng shān xiǎo",
                    "gloss": "登上高峰后群山显得矮小；比喻眼界开阔",
                }
            elif idiom == "有朋自远方来":
                idioms[idiom] = {
                    "pinyin": "yǒu péng zì yuǎn fāng lái",
                    "gloss": "有志同道合的人从远方来（《论语》）",
                }

    # Small word map: multi-char poetry lemmas + a few study words.
    words: dict[str, dict] = {}
    for term in ("故乡", "明月", "啼鸟", "黄河", "千里", "岱宗"):
        # Prefer exact word.json hit; else concatenate char glosses lightly.
        item = word_idx.get(term)
        if item:
            words[term] = {
                "pinyin": str(item.get("pinyin") or "").strip(),
                "gloss": _clean_gloss(
                    str(item.get("explanation") or item.get("desc") or ""), 100
                ),
            }
        elif all(c in entries for c in term):
            words[term] = {
                "pinyin": " ".join(entries[c].get("pinyin", "") for c in term).strip(),
                "gloss": "；".join(
                    e for c in term if (e := entries[c].get("gloss", ""))
                )[:100],
            }

    source = (
        "chinese-xinhua + poetry chars"
        if word_idx
        else "seed (vendor/chinese-xinhua missing)"
    )
    return {
        "version": 2,
        "source": source,
        "entries": entries,
        "words": words,
        "idioms": idioms,
    }


def build_syllabus_book(
    book_id: str,
    title: str,
    exam_tag: str,
    grades: list[int],
    terms: list[tuple[str, str]],
    disclaimer: str,
) -> dict:
    return {
        "id": book_id,
        "title": title,
        "examTag": exam_tag,
        "kind": "word",
        "grades": grades,
        "disclaimer": disclaimer,
        "builtin": True,
        "words": [{"word": w, "gloss": g} for w, g in terms],
    }


def main() -> None:
    word_idx = _index_by_word(_load_list(VENDOR / "data" / "word.json"))
    idiom_idx = _index_by_word(_load_list(VENDOR / "data" / "idiom.json"))

    pack = build_dict_pack(word_idx, idiom_idx)
    DICT_OUT.parent.mkdir(parents=True, exist_ok=True)
    DICT_OUT.write_text(
        json.dumps(pack, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"wrote {DICT_OUT} chars={len(pack['entries'])} idioms={len(pack['idioms'])} words={len(pack['words'])}")

    # Grade dictation lists from poetry chars + idioms.
    char_terms: list[tuple[str, str]] = []
    for ch, meta in pack["entries"].items():
        gloss = str(meta.get("gloss") or "")
        if gloss and gloss != "（离线释义待补）":
            char_terms.append((ch, gloss))
    idiom_terms = [
        (k, str(v.get("gloss") or ""))
        for k, v in pack["idioms"].items()
        if v.get("gloss")
    ]

    # Split: g7 uses first half of chars + half idioms; g8 the rest (stable sort).
    char_terms.sort(key=lambda x: x[0])
    mid = max(1, len(char_terms) // 2)
    g7_chars = char_terms[:mid] or [("疑", "怀疑；似乎"), ("霜", "近地面水汽凝成的白色冰晶")]
    g8_chars = char_terms[mid:] or [("岱", "泰山的别称"), ("宗", "祖宗；宗旨")]

    books = [
        build_syllabus_book(
            "cn_g7_dictation",
            "七年级字词听写",
            "CN-G7",
            [7],
            g7_chars[:80],
            "自建听写表：字义来自 chinese-xinhua（MIT）与诗文用字抽取，非部编教材原文。",
        ),
        build_syllabus_book(
            "cn_g8_dictation",
            "八年级字词听写",
            "CN-G8",
            [8],
            g8_chars[:80],
            "自建听写表：字义来自 chinese-xinhua（MIT）与诗文用字抽取，非部编教材原文。",
        ),
        build_syllabus_book(
            "cn_idioms_core",
            "成语核心（考试向）",
            "CN-IDIOM",
            [5, 6, 7, 8, 9],
            idiom_terms[:40] or [("守株待兔", "比喻死守经验，不知变通")],
            "成语释义来自 chinese-xinhua（MIT）；精选考试常用条，非大纲原文转载。",
        ),
    ]

    SYLLABUS_MOBILE.mkdir(parents=True, exist_ok=True)
    SYLLABUS_API.mkdir(parents=True, exist_ok=True)
    for book in books:
        for dest_dir in (SYLLABUS_MOBILE, SYLLABUS_API):
            path = dest_dir / f"{book['id']}.json"
            path.write_text(
                json.dumps(book, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
            )
            print(f"wrote {path} ({len(book['words'])} words)")

    # Keep legacy api sample path updated for older docs/scripts.
    legacy = SYLLABUS_API / "cn_g7_sample_chars.json"
    legacy.write_text(
        json.dumps(
            {
                "id": "cn_g7_sample_chars",
                "title": "七年级字词听写（样例）",
                "kind": "dictation",
                "grades": [7],
                "source": pack["source"],
                "words": [
                    {"word": w, "gloss": g, "grades": [7]}
                    for w, g in g7_chars[:40]
                ],
            },
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    print(f"wrote {legacy}")


if __name__ == "__main__":
    main()
