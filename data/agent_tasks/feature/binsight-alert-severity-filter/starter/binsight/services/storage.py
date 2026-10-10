import json
from pathlib import Path

from config import settings
from models.schemas import AnalysisRecord, RecommendationsResult


def _analyses_dir() -> Path:
    return settings.data_dir / "analyses"


def _uploads_dir() -> Path:
    return settings.data_dir / "uploads"


def save_analysis(record: AnalysisRecord) -> None:
    path = _analyses_dir() / f"{record.id}.json"
    path.write_text(record.model_dump_json(indent=2))


def load_analysis(record_id: str) -> AnalysisRecord | None:
    path = _analyses_dir() / f"{record_id}.json"
    if not path.exists():
        return None
    return AnalysisRecord.model_validate_json(path.read_text())


def list_analyses(limit: int = 50, offset: int = 0) -> list[AnalysisRecord]:
    records: list[AnalysisRecord] = []
    for p in _analyses_dir().glob("*.json"):
        try:
            records.append(AnalysisRecord.model_validate_json(p.read_text()))
        except Exception:
            continue
    records.sort(key=lambda r: r.created_at, reverse=True)
    return records[offset : offset + limit]


def delete_analysis(record_id: str) -> bool:
    json_path = _analyses_dir() / f"{record_id}.json"
    if not json_path.exists():
        return False
    record = AnalysisRecord.model_validate_json(json_path.read_text())
    image_path = _uploads_dir() / record.image_filename
    if image_path.exists():
        image_path.unlink()
    json_path.unlink()
    return True


def delete_all_analyses() -> None:
    for json_path in _analyses_dir().glob("*.json"):
        try:
            record = AnalysisRecord.model_validate_json(json_path.read_text())
            image_path = _uploads_dir() / record.image_filename
            if image_path.exists():
                image_path.unlink()
            json_path.unlink()
        except Exception:
            continue


def patch_recommendations(record_id: str, recs: RecommendationsResult) -> None:
    record = load_analysis(record_id)
    if record is None:
        raise FileNotFoundError(f"Analysis {record_id} not found")
    record.recommendations = recs
    save_analysis(record)
