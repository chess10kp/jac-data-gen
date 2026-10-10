from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from services import scraper as scraper_service

router = APIRouter()


class ScrapeRequest(BaseModel):
    url: str


@router.post("/scrape-menu")
def scrape_menu(body: ScrapeRequest):
    if not body.url.strip():
        raise HTTPException(400, "URL is required")
    try:
        items, confidence, grouped = scraper_service.scrape_menu(body.url.strip())
    except RuntimeError as e:
        raise HTTPException(422, str(e)) from e
    return {"items": items, "confidence": confidence, "grouped": grouped}
