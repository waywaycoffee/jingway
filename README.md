# 景行语文（Jingway）

景行语文是面向 K12 的考试向学习 App，按年级组织语文刷题、课内阅读、课外阅读、错题整理、知识记背、数字人伴读及作文学习（技巧教学、训练和批改）。功能范围、发布阶段及 AcquireEnglish 复用边界见[产品需求说明书](docs/product/JINGWAY_PRD.md)。

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
