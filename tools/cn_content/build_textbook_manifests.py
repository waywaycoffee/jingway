#!/usr/bin/env python3
"""Build thin textbook catalog manifests for 景行语文 (metadata only).

Sources (not bundled as corpora):
  1. TapXWorld/ChinaTextbook — 语文 PDF paths (raw GitHub / mirrors)
  2. hantang/yuwen (docs branch) — OCR markdown lesson paths
  3. zhongyuanqi/dianzi-keben — 智慧教育平台电子课本文本索引 / 网盘链接

Never writes PDF or lesson body into the repo — only titles, grades, URLs.
"""

from __future__ import annotations

import json
import re
import ssl
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "apps" / "mobile" / "assets" / "jingway" / "textbooks"
UA = "JingwayTextbookManifestBuilder/1.0 (+https://github.com/waywaycoffee/jingway)"
CTX = ssl.create_default_context()

GRADE_PATTERNS: list[tuple[re.Pattern[str], int | None, str]] = [
    (re.compile(r"一年级"), 1, "一年级"),
    (re.compile(r"二年级"), 2, "二年级"),
    (re.compile(r"三年级"), 3, "三年级"),
    (re.compile(r"四年级"), 4, "四年级"),
    (re.compile(r"五年级"), 5, "五年级"),
    (re.compile(r"六年级"), 6, "六年级"),
    (re.compile(r"七年级"), 7, "七年级"),
    (re.compile(r"八年级"), 8, "八年级"),
    (re.compile(r"九年级"), 9, "九年级"),
    (re.compile(r"必修\s*上"), 10, "高中必修上册"),
    (re.compile(r"必修\s*下"), 10, "高中必修下册"),
    (re.compile(r"选择性必修\s*上"), 11, "高中选择性必修上册"),
    (re.compile(r"选择性必修\s*中"), 11, "高中选择性必修中册"),
    (re.compile(r"选择性必修\s*下"), 12, "高中选择性必修下册"),
    (re.compile(r"高中必修上"), 10, "高中必修上册"),
    (re.compile(r"高中必修下"), 10, "高中必修下册"),
    (re.compile(r"高中选择性必修上"), 11, "高中选择性必修上册"),
    (re.compile(r"高中选择性必修中"), 11, "高中选择性必修中册"),
    (re.compile(r"高中选择性必修下"), 12, "高中选择性必修下册"),
]

VOLUME_PATTERNS: list[tuple[re.Pattern[str], str]] = [
    (re.compile(r"上册"), "上册"),
    (re.compile(r"下册"), "下册"),
    (re.compile(r"中册"), "中册"),
]


def http_get(url: str, *, timeout: int = 90) -> bytes:
    """GET with percent-encoded path (idempotent for already-encoded URLs)."""
    parts = urllib.parse.urlsplit(url)
    # Unquote then re-quote each segment so Chinese and %XX both work once.
    segs = [
        urllib.parse.quote(urllib.parse.unquote(p), safe="")
        if p
        else ""
        for p in parts.path.split("/")
    ]
    # Keep empty leading segment for absolute paths ("/foo").
    enc_path = "/".join(segs)
    enc = urllib.parse.urlunsplit(
        (parts.scheme, parts.netloc, enc_path, parts.query, parts.fragment)
    )
    req = urllib.request.Request(
        enc,
        headers={"User-Agent": UA, "Accept": "application/vnd.github+json,*/*"},
    )
    with urllib.request.urlopen(req, context=CTX, timeout=timeout) as resp:
        return resp.read()


def http_get_json(url: str) -> object:
    return json.loads(http_get(url).decode("utf-8"))


def encode_path(path: str) -> str:
    return "/".join(urllib.parse.quote(seg) for seg in path.split("/"))


def infer_band(path: str) -> str:
    if path.startswith("小学") or "小学" in path[:6]:
        return "小学"
    if path.startswith("初中") or "初中" in path[:6]:
        return "初中"
    if path.startswith("高中") or "高中" in path[:6] or "必修" in path:
        return "高中"
    return "其他"


def infer_grade(text: str) -> tuple[int | None, str]:
    for pat, grade, label in GRADE_PATTERNS:
        if pat.search(text):
            return grade, label
    return None, ""


def infer_volume(text: str) -> str:
    for pat, label in VOLUME_PATTERNS:
        if pat.search(text):
            return label
    return ""


def write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"wrote {path.relative_to(ROOT)} ({len(json.dumps(payload))} chars)")


def build_china_textbook() -> dict:
    tree = http_get_json(
        "https://api.github.com/repos/TapXWorld/ChinaTextbook/git/trees/master?recursive=1"
    )
    if not isinstance(tree, dict) or "tree" not in tree:
        raise RuntimeError(f"ChinaTextbook tree failed: {tree}")
    items: list[dict] = []
    for node in tree["tree"]:
        if node.get("type") != "blob":
            continue
        path = node.get("path") or ""
        if not path.endswith(".pdf"):
            continue
        # Prefer 语文 textbooks; skip 书法练习指导 clutter.
        if "/语文/" not in path and not path.startswith("高中/语文"):
            continue
        if "书法" in path:
            continue
        name = path.rsplit("/", 1)[-1].removesuffix(".pdf")
        grade, grade_label = infer_grade(path + name)
        volume = infer_volume(path + name)
        band = infer_band(path)
        raw = (
            "https://raw.githubusercontent.com/TapXWorld/ChinaTextbook/master/"
            + encode_path(path)
        )
        html = (
            "https://github.com/TapXWorld/ChinaTextbook/blob/master/"
            + encode_path(path)
        )
        items.append(
            {
                "id": f"china_{abs(hash(path)) % (10**12)}",
                "title": name,
                "subject": "语文",
                "band": band,
                "grade": grade,
                "gradeLabel": grade_label or band,
                "volume": volume,
                "edition": "统编版",
                "path": path,
                "remoteUrl": raw,
                "githubUrl": html,
                "mirrors": [
                    f"https://ghfast.top/{raw}",
                    f"https://mirror.ghproxy.com/{raw}",
                ],
                "sizeBytes": int(node.get("size") or 0),
                "action": "pdf",
            }
        )
    items.sort(key=lambda x: (x.get("grade") or 99, x.get("volume") or "", x["title"]))
    # Stable ids from path
    for it in items:
        it["id"] = "china_" + re.sub(r"[^a-zA-Z0-9]+", "_", it["path"])[:64].strip("_")
    return {
        "source": "china_textbook",
        "repo": "https://github.com/TapXWorld/ChinaTextbook",
        "licenseNote": "版权归原出版社；仓库为民间整理的 PDF 索引，景行仅提供目录与按需打开，不内置正文。",
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "subjectFilter": "语文",
        "items": items,
    }


def build_yuwen() -> dict:
    tree = http_get_json(
        "https://api.github.com/repos/hantang/yuwen/git/trees/docs?recursive=1"
    )
    if not isinstance(tree, dict) or "tree" not in tree:
        raise RuntimeError(f"yuwen docs tree failed: {tree}")

    volumes: dict[str, dict] = {}
    lessons: list[dict] = []

    for node in tree["tree"]:
        if node.get("type") != "blob":
            continue
        path = node.get("path") or ""
        if not path.endswith(".md"):
            continue
        if path in {"README.md", "CHANGELOG.md"} or path.startswith("archives/"):
            continue
        top = path.split("/", 1)[0]
        if not re.match(r"^\d{2}[abcx]-", top):
            continue
        if top not in volumes:
            title = top.split("-", 1)[-1] if "-" in top else top
            grade, grade_label = infer_grade(title)
            # folder codes: 01a = 一年级上, 10a = 高中必修上
            code = top[:3]
            if grade is None:
                try:
                    n = int(top[:2])
                    if 1 <= n <= 9:
                        grade = n
                        grade_label = f"{n}年级" if n <= 6 else f"{['七','八','九'][n-7]}年级"
                    elif n == 10:
                        grade = 10
                        grade_label = "高中必修"
                    elif n == 11:
                        grade = 11
                        grade_label = "高中选择性必修"
                except ValueError:
                    pass
            band = (
                "小学"
                if (grade or 0) <= 6
                else "初中"
                if (grade or 0) <= 9
                else "高中"
            )
            volumes[top] = {
                "id": f"yuwen_vol_{top}",
                "code": top,
                "title": title,
                "band": band,
                "grade": grade,
                "gradeLabel": grade_label or title,
                "volume": infer_volume(title) or ("上册" if "a" in code else "下册" if "b" in code or "x" in code else ""),
                "indexPath": f"{top}/index.md" if path.endswith("/index.md") else None,
            }
        if path.endswith("/index.md"):
            volumes[top]["indexPath"] = path
            continue
        if "/text/" not in path:
            continue
        # Skip unit index.md under text/
        if path.endswith("/index.md"):
            continue
        parts = path.split("/")
        unit = parts[2] if len(parts) > 3 else ""
        name = parts[-1].removesuffix(".md")
        if name in {"index"}:
            continue
        grade = volumes[top]["grade"]
        # Store repo-relative path only; app builds raw + mirror URLs at runtime.
        lessons.append(
            {
                "id": "yuwen_" + re.sub(r"[^a-zA-Z0-9\u4e00-\u9fff]+", "_", path)[:80],
                "title": name,
                "volumeCode": top,
                "volumeTitle": volumes[top]["title"],
                "unit": unit,
                "band": volumes[top]["band"],
                "grade": grade,
                "gradeLabel": volumes[top]["gradeLabel"],
                "volume": volumes[top]["volume"],
                "path": path,
                "action": "markdown",
            }
        )

    vol_list = sorted(volumes.values(), key=lambda v: v["code"])
    lessons.sort(
        key=lambda x: (x.get("grade") or 99, x["volumeCode"], x.get("unit") or "", x["title"])
    )
    return {
        "source": "yuwen",
        "repo": "https://github.com/hantang/yuwen",
        "branch": "docs",
        "rawBase": "https://raw.githubusercontent.com/hantang/yuwen/docs/",
        "mirrorPrefixes": [
            "https://ghfast.top/",
            "https://mirror.ghproxy.com/",
        ],
        "licenseNote": "课文原文版权归原作者/出版社；yuwen 为业余 OCR 整理，严禁商用。景行仅按需拉取，不内置正文。",
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "volumes": vol_list,
        "items": lessons,
    }


_LINK_RE = re.compile(
    r"(https?://[^\s\)\]<>\"']+)|(提取码[：:]\s*([a-zA-Z0-9]+))",
    re.IGNORECASE,
)
_BAIDU_RE = re.compile(r"https?://pan\.baidu\.com/[^\s\)\]<>\"']+")
_QUARK_RE = re.compile(r"https?://pan\.quark\.cn/[^\s\)\]<>\"']+")
_SMARTEDU_RE = re.compile(r"https?://(?:basic\.)?smartedu\.cn/[^\s\)\]<>\"']+")


def _parse_dianzi_body(title: str, band: str, body: str, github_path: str) -> dict:
    baidu = _BAIDU_RE.findall(body)
    quark = _QUARK_RE.findall(body)
    smartedu = _SMARTEDU_RE.findall(body) or ["https://basic.smartedu.cn/"]
    pwd_m = re.search(r"提取码[：:]\s*([a-zA-Z0-9]+)", body)
    grade, grade_label = infer_grade(title + body[:200])
    links: list[dict] = []
    for u in baidu:
        links.append({"label": "百度网盘", "url": u, "kind": "netdisk"})
    for u in quark:
        links.append({"label": "夸克网盘", "url": u, "kind": "netdisk"})
    for u in smartedu[:1]:
        links.append({"label": "国家中小学智慧教育平台", "url": u, "kind": "platform"})
    github_url = (
        "https://github.com/zhongyuanqi/dianzi-keben/blob/main/"
        + encode_path(github_path)
    )
    links.append({"label": "GitHub 索引页", "url": github_url, "kind": "github"})
    return {
        "id": "dianzi_" + re.sub(r"[^a-zA-Z0-9\u4e00-\u9fff]+", "_", github_path)[:64],
        "title": title,
        "subject": "语文",
        "band": band,
        "grade": grade,
        "gradeLabel": grade_label or band,
        "volume": "",
        "path": github_path,
        "password": pwd_m.group(1) if pwd_m else None,
        "links": links,
        "action": "external",
        "note": "电子课本本体在智慧教育平台或网盘；景行仅收录索引链接。",
    }


def build_dianzi() -> dict:
    targets = [
        ("小学电子课本/小学语文电子课本.md", "小学语文电子课本", "小学"),
        ("初中电子课本/初中语文电子课本.md", "初中语文电子课本", "初中"),
        ("高中电子课本/高中语文电子课本", "高中语文电子课本", "高中"),
        (
            "小学电子课本/小学语文书法练习指导电子课本.md",
            "小学语文书法练习指导",
            "小学",
        ),
    ]
    items: list[dict] = []
    for path, title, band in targets:
        raw = (
            "https://raw.githubusercontent.com/zhongyuanqi/dianzi-keben/main/"
            + encode_path(path)
        )
        try:
            body = http_get(raw).decode("utf-8", errors="replace")
        except urllib.error.HTTPError as e:
            print(f"warn: skip {path}: {e}", file=sys.stderr)
            continue
        items.append(_parse_dianzi_body(title, band, body, path))
    return {
        "source": "dianzi_keben",
        "repo": "https://github.com/zhongyuanqi/dianzi-keben",
        "platform": "https://basic.smartedu.cn/",
        "licenseNote": "内容来自国家中小学智慧教育平台整理索引；版权归教育部/出版社。景行只提供外链，不托管 PDF。",
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "items": items,
    }


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    print("building ChinaTextbook manifest…")
    china = build_china_textbook()
    write_json(OUT_DIR / "china_textbook.json", china)
    print(f"  {len(china['items'])} PDFs")

    print("building yuwen (docs) manifest…")
    yuwen = build_yuwen()
    write_json(OUT_DIR / "yuwen.json", yuwen)
    print(f"  {len(yuwen['volumes'])} volumes, {len(yuwen['items'])} lessons")

    print("building dianzi-keben manifest…")
    dianzi = build_dianzi()
    write_json(OUT_DIR / "dianzi_keben.json", dianzi)
    print(f"  {len(dianzi['items'])} index entries")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
