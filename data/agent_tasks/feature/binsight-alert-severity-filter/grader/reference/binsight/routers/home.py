from fastapi import APIRouter, HTTPException

from config import settings
from services import home_content as home_content_service

router = APIRouter()


@router.get("/home-content")
def get_home_content():
    try:
        content = home_content_service.get_home_content()
    except (RuntimeError, ValueError) as exc:
        raise HTTPException(502, f"Home content generation failed: {exc}") from exc
    return content.model_dump(mode="json")


@router.get("/app-config")
def get_app_config():
    return {
        "reset_analyses_on_load": settings.reset_analyses_on_load,
    }
