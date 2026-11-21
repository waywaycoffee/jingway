#!/usr/bin/env python3
"""Build grade-tagged exam_core poetry pack.

Prefers simplified texts. When vendor/chinese-poetry is present, merges additional
唐詩三百首 titles (converted to simplified if zhconv is available; otherwise uses
the curated SIMPLIFIED_EXTRA pack only).

Writes:
  - apps/mobile/assets/jingway/poetry/exam_core.json
  - services/api/data/poetry/exam_core.json
"""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
VENDOR_TANG = ROOT / "vendor/chinese-poetry/蒙学/tangshisanbaishou.json"
OUT_MOBILE = ROOT / "apps/mobile/assets/jingway/poetry/exam_core.json"
OUT_API = ROOT / "services/api/data/poetry/exam_core.json"

# Curated K12 exam subset (simplified, public-domain classical texts).
CURATED: list[dict] = [
    {
        "id": "jingye_si",
        "title": "静夜思",
        "author": "李白",
        "dynasty": "唐",
        "grades": [1, 2, 3, 4, 5, 6, 7],
        "lines": ["床前明月光", "疑是地上霜", "举头望明月", "低头思故乡"],
    },
    {
        "id": "chun_xiao",
        "title": "春晓",
        "author": "孟浩然",
        "dynasty": "唐",
        "grades": [1, 2, 3, 4, 5, 6],
        "lines": ["春眠不觉晓", "处处闻啼鸟", "夜来风雨声", "花落知多少"],
    },
    {
        "id": "deng_guanquelou",
        "title": "登鹳雀楼",
        "author": "王之涣",
        "dynasty": "唐",
        "grades": [2, 3, 4, 5, 6, 7],
        "lines": ["白日依山尽", "黄河入海流", "欲穷千里目", "更上一层楼"],
    },
    {
        "id": "wang_yue",
        "title": "望岳",
        "author": "杜甫",
        "dynasty": "唐",
        "grades": [7, 8, 9],
        "lines": [
            "岱宗夫如何",
            "齐鲁青未了",
            "造化钟神秀",
            "阴阳割昏晓",
            "荡胸生曾云",
            "决眦入归鸟",
            "会当凌绝顶",
            "一览众山小",
        ],
    },
    {
        "id": "ci_cheng",
        "title": "次北固山下",
        "author": "王湾",
        "dynasty": "唐",
        "grades": [7, 8],
        "lines": [
            "客路青山外",
            "行舟绿水前",
            "潮平两岸阔",
            "风正一帆悬",
            "海日生残夜",
            "江春入旧年",
            "乡书何处达",
            "归雁洛阳边",
        ],
    },
    {
        "id": "lunyu_xueer",
        "title": "论语·学而（节选）",
        "author": "孔子",
        "dynasty": "春秋",
        "grades": [7, 8, 9],
        "lines": [
            "学而时习之",
            "不亦说乎",
            "有朋自远方来",
            "不亦乐乎",
            "人不知而不愠",
            "不亦君子乎",
        ],
    },
    {
        "id": "xiangsi",
        "title": "相思",
        "author": "王维",
        "dynasty": "唐",
        "grades": [3, 4, 5, 6, 7],
        "lines": ["红豆生南国", "春来发几枝", "愿君多采撷", "此物最相思"],
    },
    {
        "id": "min_nong",
        "title": "悯农（其一）",
        "author": "李绅",
        "dynasty": "唐",
        "grades": [1, 2, 3, 4],
        "lines": ["锄禾日当午", "汗滴禾下土", "谁知盘中餐", "粒粒皆辛苦"],
    },
    {
        "id": "ye_yu_ji_bei",
        "title": "夜雨寄北",
        "author": "李商隐",
        "dynasty": "唐",
        "grades": [7, 8, 9],
        "lines": ["君问归期未有期", "巴山夜雨涨秋池", "何当共剪西窗烛", "却话巴山夜雨时"],
    },
    {
        "id": "huang_he_lou",
        "title": "黄鹤楼送孟浩然之广陵",
        "author": "李白",
        "dynasty": "唐",
        "grades": [7, 8],
        "lines": [
            "故人西辞黄鹤楼",
            "烟花三月下扬州",
            "孤帆远影碧空尽",
            "唯见长江天际流",
        ],
    },
    {
        "id": "wang_lu_shan_pu_bu",
        "title": "望庐山瀑布",
        "author": "李白",
        "dynasty": "唐",
        "grades": [3, 4, 5, 6, 7],
        "lines": ["日照香炉生紫烟", "遥看瀑布挂前川", "飞流直下三千尺", "疑是银河落九天"],
    },
    {
        "id": "zao_fa_baidicheng",
        "title": "早发白帝城",
        "author": "李白",
        "dynasty": "唐",
        "grades": [4, 5, 6, 7],
        "lines": ["朝辞白帝彩云间", "千里江陵一日还", "两岸猿声啼不住", "轻舟已过万重山"],
    },
    {
        "id": "jiang_xue",
        "title": "江雪",
        "author": "柳宗元",
        "dynasty": "唐",
        "grades": [4, 5, 6, 7],
        "lines": ["千山鸟飞绝", "万径人踪灭", "孤舟蓑笠翁", "独钓寒江雪"],
    },
    {
        "id": "feng_qiao_ye_bo",
        "title": "枫桥夜泊",
        "author": "张继",
        "dynasty": "唐",
        "grades": [5, 6, 7, 8],
        "lines": ["月落乌啼霜满天", "江枫渔火对愁眠", "姑苏城外寒山寺", "夜半钟声到客船"],
    },
    {
        "id": "you_zi_yin",
        "title": "游子吟",
        "author": "孟郊",
        "dynasty": "唐",
        "grades": [4, 5, 6, 7],
        "lines": ["慈母手中线", "游子身上衣", "临行密密缝", "意恐迟迟归", "谁言寸草心", "报得三春晖"],
    },
    {
        "id": "qiu_si",
        "title": "秋思",
        "author": "马致远",
        "dynasty": "元",
        "grades": [7, 8, 9],
        "lines": ["枯藤老树昏鸦", "小桥流水人家", "古道西风瘦马", "夕阳西下", "断肠人在天涯"],
    },
    {
        "id": "shui_diao_ge_tou",
        "title": "水调歌头·明月几时有（节选）",
        "author": "苏轼",
        "dynasty": "宋",
        "grades": [8, 9],
        "lines": [
            "明月几时有",
            "把酒问青天",
            "不知天上宫阙",
            "今夕是何年",
            "我欲乘风归去",
            "又恐琼楼玉宇",
            "高处不胜寒",
            "起舞弄清影",
            "何似在人间",
        ],
    },
    {
        "id": "qing_ping_yue_cun_ju",
        "title": "清平乐·村居",
        "author": "辛弃疾",
        "dynasty": "宋",
        "grades": [5, 6, 7],
        "lines": [
            "茅檐低小",
            "溪上青青草",
            "醉里吴音相媚好",
            "白发谁家翁媪",
            "大儿锄豆溪东",
            "中儿正织鸡笼",
            "最喜小儿亡赖",
            "溪头卧剥莲蓬",
        ],
    },
]

# Titles we attempt to pull from tangshisanbaishou (traditional source → simplify).
VENDOR_TITLE_GRADES: dict[str, list[int]] = {
    "静夜思": [1, 2, 3, 4, 5, 6, 7],
    "春晓": [1, 2, 3, 4, 5, 6],
    "登鹳雀楼": [2, 3, 4, 5, 6, 7],
    "相思": [3, 4, 5, 6, 7],
    "九月九日忆山东兄弟": [5, 6, 7],
    "芙蓉楼送辛渐": [7, 8],
    "凉州词": [4, 5, 6, 7],
    "出塞": [7, 8, 9],
    "送元二使安西": [6, 7, 8],
    "竹里馆": [5, 6, 7],
    "杂诗": [6, 7],
}

# Minimal traditional→simplified for Tang-poetry titles/lines when zhconv is absent.
_T2S = str.maketrans(
    {
        "住": "住",
        "來": "来",
        "兩": "两",
        "別": "别",
        "勸": "劝",
        "千": "千",
        "吳": "吴",
        "問": "问",
        "啼": "啼",
        "國": "国",
        "報": "报",
        "塵": "尘",
        "壺": "壶",
        "將": "将",
        "對": "对",
        "層": "层",
        "山": "山",
        "峽": "峡",
        "幾": "几",
        "影": "影",
        "徑": "径",
        "復": "复",
        "憶": "忆",
        "應": "应",
        "採": "采",
        "擷": "撷",
        "明": "明",
        "時": "时",
        "晝": "昼",
        "暉": "晖",
        "曉": "晓",
        "東": "东",
        "棄": "弃",
        "楊": "杨",
        "楓": "枫",
        "樓": "楼",
        "樹": "树",
        "歸": "归",
        "涼": "凉",
        "淚": "泪",
        "淵": "渊",
        "渙": "涣",
        "滅": "灭",
        "滿": "满",
        "漁": "渔",
        "漢": "汉",
        "漸": "渐",
        "澗": "涧",
        "瀧": "泷",
        "灘": "滩",
        "灣": "湾",
        "為": "为",
        "無": "无",
        "煙": "烟",
        "猿": "猿",
        "獨": "独",
        "爲": "为",
        "異": "异",
        "疾": "疾",
        "發": "发",
        "盡": "尽",
        "窮": "穷",
        "笠": "笠",
        "節": "节",
        "紳": "绅",
        "絕": "绝",
        "維": "维",
        "綺": "绮",
        "線": "线",
        "縫": "缝",
        "繼": "继",
        "羨": "羡",
        "聞": "闻",
        "聲": "声",
        "臨": "临",
        "與": "与",
        "舉": "举",
        "華": "华",
        "萬": "万",
        "葉": "叶",
        "蓋": "盖",
        "蓑": "蓑",
        "蘆": "芦",
        "蘇": "苏",
        "蘭": "兰",
        "處": "处",
        "裡": "里",
        "見": "见",
        "親": "亲",
        "覺": "觉",
        "詞": "词",
        "賦": "赋",
        "蹤": "踪",
        "軾": "轼",
        "輕": "轻",
        "連": "连",
        "遅": "迟",
        "過": "过",
        "遙": "遥",
        "遠": "远",
        "遲": "迟",
        "還": "还",
        "鄉": "乡",
        "重": "重",
        "釣": "钓",
        "鐘": "钟",
        "長": "长",
        "開": "开",
        "間": "间",
        "關": "关",
        "陰": "阴",
        "陽": "阳",
        "際": "际",
        "隱": "隐",
        "雜": "杂",
        "離": "离",
        "雲": "云",
        "靜": "静",
        "響": "响",
        "頭": "头",
        "願": "愿",
        "風": "风",
        "飛": "飞",
        "餘": "余",
        "館": "馆",
        "馬": "马",
        "驚": "惊",
        "鳥": "鸟",
        "鴉": "鸦",
        "鵰": "雕",
        "鵲": "鹊",
        "鶯": "莺",
        "鶴": "鹤",
        "鷗": "鸥",
        "鷺": "鹭",
        "鸛": "鹳",
        "黃": "黄",
        "龍": "龙",
    }
)


def _to_simplified(text: str) -> str:
    try:
        import zhconv  # type: ignore

        return zhconv.convert(text, "zh-cn")
    except Exception:
        return text.translate(_T2S)


def _slug(title: str) -> str:
    """Stable ASCII-ish id; Chinese titles get a short hash suffix."""
    ascii_part = re.sub(r"[^a-zA-Z0-9]+", "_", title).strip("_").lower()
    if ascii_part and re.fullmatch(r"[a-z0-9_]+", ascii_part):
        return ascii_part
    # Prefer curated known titles.
    known = {
        "芙蓉楼送辛渐": "fu_rong_lou_song_xin_jian",
        "九月九日忆山东兄弟": "jiu_yue_jiu_ri_yi_shan_dong",
        "凉州词": "liang_zhou_ci",
        "出塞": "chu_sai",
        "送元二使安西": "song_yuan_er_shi_an_xi",
        "竹里馆": "zhu_li_guan",
        "杂诗": "za_shi",
    }
    if title in known:
        return known[title]
    digest = abs(hash(title)) % 10_000_000
    return f"poem_{digest}"


def _split_lines(paragraphs: list[str]) -> list[str]:
    lines: list[str] = []
    for para in paragraphs:
        simplified = _to_simplified(para)
        # Split on classic punctuation while keeping short line units.
        parts = re.split(r"[，。？！；、,.!?;]+", simplified)
        for part in parts:
            p = part.strip()
            if p:
                lines.append(p)
    return lines


def _load_vendor_poems() -> list[dict]:
    if not VENDOR_TANG.exists():
        return []
    raw = json.loads(VENDOR_TANG.read_text(encoding="utf-8"))
    content = raw.get("content") if isinstance(raw, dict) else None
    if not isinstance(content, list):
        return []
    out: list[dict] = []
    for section in content:
        if not isinstance(section, dict):
            continue
        for poem in section.get("content") or []:
            if not isinstance(poem, dict):
                continue
            title_t = str(poem.get("chapter") or "").strip()
            author_t = str(poem.get("author") or "").strip()
            paragraphs = poem.get("paragraphs") or []
            if not title_t or not isinstance(paragraphs, list):
                continue
            title = _to_simplified(title_t)
            if title not in VENDOR_TITLE_GRADES:
                continue
            lines = _split_lines([str(x) for x in paragraphs])
            if len(lines) < 2:
                continue
            out.append(
                {
                    "id": _slug(title),
                    "title": title,
                    "author": _to_simplified(author_t) or "佚名",
                    "dynasty": "唐",
                    "grades": VENDOR_TITLE_GRADES[title],
                    "lines": lines,
                }
            )
    return out


def _merge(items: list[dict]) -> list[dict]:
    by_title: dict[str, dict] = {}
    for item in items:
        title = item["title"]
        # Prefer curated (already in map) over vendor rewrite of same title.
        if title in by_title:
            continue
        by_title[title] = item
    # Stable: curated order first, then extras.
    ordered: list[dict] = []
    seen: set[str] = set()
    for item in CURATED:
        ordered.append(item)
        seen.add(item["title"])
    for item in items:
        if item["title"] in seen:
            continue
        ordered.append(item)
        seen.add(item["title"])
    return ordered


def main() -> None:
    vendor_items = _load_vendor_poems()
    merged = _merge(CURATED + vendor_items)
    # Deduplicate ids
    used_ids: set[str] = set()
    for item in merged:
        iid = item["id"]
        if iid in used_ids:
            item["id"] = f"{iid}_{len(used_ids)}"
        used_ids.add(item["id"])

    data = {
        "version": 2,
        "source": "chinese-poetry public-domain texts; curated exam subset"
        + (" + tangshisanbaishou" if vendor_items else ""),
        "items": merged,
    }
    payload = json.dumps(data, ensure_ascii=False, indent=2) + "\n"
    OUT_MOBILE.parent.mkdir(parents=True, exist_ok=True)
    OUT_API.parent.mkdir(parents=True, exist_ok=True)
    OUT_MOBILE.write_text(payload, encoding="utf-8")
    OUT_API.write_text(payload, encoding="utf-8")
    print(f"wrote {OUT_MOBILE} ({len(merged)} items; vendor_extra={len(vendor_items)})")


if __name__ == "__main__":
    main()
