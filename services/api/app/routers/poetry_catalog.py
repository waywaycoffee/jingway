"""Grade-tagged classical poetry catalog for 景行语文."""

from __future__ import annotations

import json
from pathlib import Path

from fastapi import APIRouter, HTTPException, Query

router = APIRouter(prefix="/poetry", tags=["poetry"])


def _poetry_root() -> Path:
    return Path(__file__).resolve().parents[2] / "data" / "poetry"


def _load_exam_core() -> dict:
    path = _poetry_root() / "exam_core.json"
    if not path.is_file():
        return {"version": 1, "items": []}
    return json.loads(path.read_text(encoding="utf-8"))


@router.get("/catalog")
def poetry_catalog(grade: int | None = Query(default=None, ge=1, le=12)):
    data = _load_exam_core()
    items = data.get("items") or []
    if grade is not None:
        items = [
            it
            for it in items
            if isinstance(it, dict) and grade in (it.get("grades") or [])
        ]
    return {
        "version": data.get("version", 1),
        "count": len(items),
        "items": items,
    }


@router.get("/{unit_id}")
def poetry_unit(unit_id: str):
    data = _load_exam_core()
    for it in data.get("items") or []:
        if isinstance(it, dict) and it.get("id") == unit_id:
            return it
    raise HTTPException(status_code=404, detail="poetry unit not found")
