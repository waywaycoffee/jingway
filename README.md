# 景行语文（Jingway）

K12 **考试向**语文学习 App：按年级匹配字词听写、古诗文默写、错题 FSRS 回流。

技术底座 fork 自 [AcquireEnglish](https://github.com/waywaycoffee/AcquireEnglish)（Flutter + FastAPI），产品面为独立应用。

## 仓库

```text
apps/mobile/     Flutter 客户端（包名 com.jingway.chinese）
services/api/    FastAPI
tools/cn_content/  xinhua / poetry / dictionary 内容管线
docs/            归因与 P0 验收
```

## 快速开始

### API

```bash
cd services/api
python3.12 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
uvicorn app.main:app --reload --host 0.0.0.0 --port 8001
```

### Mobile

```bash
cd apps/mobile
flutter pub get
flutter run --flavor prod
```

### 内容 vendor（可选）

```bash
chmod +x tools/cn_content/fetch_vendors.sh
./tools/cn_content/fetch_vendors.sh
python3 tools/cn_content/build_xinhua_syllabus.py
python3 tools/cn_content/build_poetry_exam.py
```

## 远程

- `origin` → `waywaycoffee/jingway`（本产品）
- `upstream` → `waywaycoffee/AcquireEnglish`（引擎回迁）
