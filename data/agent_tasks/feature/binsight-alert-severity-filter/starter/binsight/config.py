from pathlib import Path
from typing import Literal

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    llm_provider: Literal["anthropic", "openrouter"] = "anthropic"
    anthropic_api_key: str = ""
    anthropic_vision_model: str = "claude-sonnet-4-6"
    anthropic_text_model: str = "claude-sonnet-4-6"
    openrouter_api_key: str = ""
    openrouter_vision_model: str = ""
    openrouter_text_model: str = ""
    vision_model: str = "openai/gpt-4o"
    text_model: str = "openai/gpt-4o-mini"
    analysis_backend: Literal["jac", "python", "auto"] = "python"
    recommendations_backend: Literal["jac", "python", "auto"] = "python"
    home_backend: Literal["jac", "python", "auto"] = "auto"
    jac_service_url: str = ""
    jac_walker_name: str = "AnalyzeWaste"
    jac_recommendations_walker_name: str = "GenerateRecommendations"
    jac_home_walker_name: str = "GetHomePageContent"
    reset_analyses_on_load: bool = False
    data_dir: Path = Path("data")
    constant_items_file: Path = Path("constant_items.txt")
    default_constant_items: list[str] = [
        "salad greens",
        "salad toppings",
        "fresh fruit",
        "bread",
        "dessert",
        "condiments",
        "coffee",
        "tea",
        "ice",
    ]
    max_image_size_mb: int = 10

    class Config:
        env_file = ".env"


settings = Settings()
