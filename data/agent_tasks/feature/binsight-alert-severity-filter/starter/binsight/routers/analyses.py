import uuid
from datetime import datetime, timezone
from pathlib import Path

from fastapi import APIRouter, File, Form, HTTPException, Query, UploadFile
from fastapi.responses import JSONResponse

from config import settings
from models.schemas import AnalysisRecord
from services import scraper as scraper_service
from services import storage, vision

router = APIRouter()


@router.post("/analyses", status_code=201)
async def create_analysis(
    image: UploadFile = File(...),
    menu_source: str = Form("none"),
    menu_url: str = Form(""),
    menu_text: str = Form(""),
):
    # Validate image size
    content = await image.read()
    if len(content) > settings.max_image_size_mb * 1024 * 1024:
        raise HTTPException(413, f"Image exceeds {settings.max_image_size_mb}MB limit")

    # Determine file extension
    ext = Path(image.filename or "upload.jpg").suffix.lower() or ".jpg"
    record_id = str(uuid.uuid4())
    image_filename = f"{record_id}{ext}"
    image_path = settings.data_dir / "uploads" / image_filename
    image_path.write_bytes(content)

    # Resolve menu items
    menu_items: list[str] = []
    resolved_url: str | None = None

    if menu_source == "url" and menu_url.strip():
        resolved_url = menu_url.strip()
        try:
            menu_items, _, _ = scraper_service.scrape_menu(resolved_url)
        except RuntimeError:
            menu_items = []
    elif menu_source == "manual" and menu_text.strip():
        menu_items = scraper_service.normalize_manual_menu_items(menu_text)

    constant_items = vision.load_constant_items()

    # Run LLM vision analysis
    try:
        items, summary, notes = vision.analyze_waste(image_path, menu_items, constant_items)
    except (RuntimeError, ValueError) as e:
        image_path.unlink(missing_ok=True)
        raise HTTPException(502, f"Vision analysis failed: {e}") from e

    record = AnalysisRecord(
        id=record_id,
        created_at=datetime.now(timezone.utc),
        image_filename=image_filename,
        menu_source=menu_source,  # type: ignore[arg-type]
        menu_url=resolved_url,
        menu_items=menu_items,
        items=items,
        summary=summary,
        notes=notes,
    )
    storage.save_analysis(record)
    return JSONResponse(content=record.model_dump(mode="json"), status_code=201)


@router.get("/analyses")
def list_analyses(limit: int = 50, offset: int = 0):
    records = storage.list_analyses(limit=limit, offset=offset)
    return [r.model_dump(mode="json") for r in records]


@router.get("/analyses/{record_id}")
def get_analysis(record_id: str):
    record = storage.load_analysis(record_id)
    if record is None:
        raise HTTPException(404, "Analysis not found")
    return record.model_dump(mode="json")


@router.delete("/analyses/{record_id}", status_code=204)
def delete_analysis(record_id: str):
    deleted = storage.delete_analysis(record_id)
    if not deleted:
        raise HTTPException(404, "Analysis not found")

@router.delete("/analyses", status_code=204)
def delete_all_analyses(confirm: bool = Query(False)):
    if not confirm and not settings.reset_analyses_on_load:
        return
    storage.delete_all_analyses()
