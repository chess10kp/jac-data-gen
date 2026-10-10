from __future__ import annotations
from datetime import datetime
from typing import Literal, Optional
from pydantic import BaseModel, field_validator

WASTE_CATEGORIES = (
    "protein", "grain", "dairy", "fruit", "vegetable", "beverage",
    "dessert", "bakery", "snack", "sauce", "soup", "mixed", "other",
)

# Aliases the LLM often returns — map them onto our canonical set.
_CATEGORY_ALIASES = {
    "meat": "protein", "poultry": "protein", "seafood": "protein", "fish": "protein", "egg": "protein", "eggs": "protein", "legume": "protein", "legumes": "protein", "beans": "protein", "tofu": "protein",
    "grains": "grain", "rice": "grain", "pasta": "grain", "cereal": "grain", "starch": "grain",
    "cheese": "dairy", "yogurt": "dairy", "milk": "dairy",
    "fruits": "fruit",
    "vegetables": "vegetable", "veggies": "vegetable", "salad": "vegetable", "greens": "vegetable",
    "drink": "beverage", "drinks": "beverage", "juice": "beverage", "coffee": "beverage", "tea": "beverage", "soda": "beverage",
    "sweet": "dessert", "sweets": "dessert", "pastry": "dessert", "cake": "dessert", "cookie": "dessert", "ice cream": "dessert", "candy": "dessert", "chocolate": "dessert",
    "bread": "bakery", "muffin": "bakery", "bagel": "bakery", "pastries": "bakery",
    "snacks": "snack", "chips": "snack",
    "sauces": "sauce", "condiment": "sauce", "condiments": "sauce", "dressing": "sauce", "syrup": "sauce", "gravy": "sauce",
    "soups": "soup", "stew": "soup", "broth": "soup",
    "combo": "mixed", "combination": "mixed", "leftovers": "mixed", "scraps": "mixed",
}


class WasteItem(BaseModel):
    food: str
    category: Literal[
        "protein", "grain", "dairy", "fruit", "vegetable", "beverage",
        "dessert", "bakery", "snack", "sauce", "soup", "mixed", "other",
    ]
    estimated_weight_oz: float
    estimated_portion_wasted_pct: float
    estimated_cost_usd: float
    avoidable: bool

    @field_validator("category", mode="before")
    @classmethod
    def _coerce_category(cls, v):
        """Normalize LLM-provided categories onto our canonical set.
        Unknown values fall back to "other" instead of raising — we'd rather
        keep the item than drop a whole image's analysis over a novel label.
        """
        if not isinstance(v, str):
            return "other"
        key = v.strip().lower()
        if not key:
            return "other"
        if key in WASTE_CATEGORIES:
            return key
        if key in _CATEGORY_ALIASES:
            return _CATEGORY_ALIASES[key]
        return "other"


class WasteSummary(BaseModel):
    total_items: int
    total_estimated_weight_oz: float
    total_estimated_cost_usd: float
    most_wasted_category: str
    waste_severity: Literal["low", "medium", "high", "critical"]
    avoidable_weight_oz: float
    unavoidable_weight_oz: float
    avoidable_cost_usd: float
    unavoidable_cost_usd: float


class RecommendationInsight(BaseModel):
    priority: Literal["high", "medium", "low"]
    action: str
    rationale: str


class RecommendationsResult(BaseModel):
    generated_at: datetime
    menu_delta: list[str]
    insights: list[RecommendationInsight]
    summary_text: str


class HomeImpactCard(BaseModel):
    label: str
    value: str
    meta: str


class HomeWorkflowStep(BaseModel):
    index: str
    title: str
    description: str


class HomeMediaCard(BaseModel):
    image_url: str
    alt: str
    label: str


class HomeContent(BaseModel):
    hero_kicker: str
    hero_title: str
    hero_body: str
    start_label: str
    jac_label: str
    impacts: list[HomeImpactCard]
    pitch_title: str
    pitch_body: list[str]
    workflow_steps: list[HomeWorkflowStep]
    jac_title: str
    jac_body: str
    jac_snippet: str
    jac_chips: list[str]
    media_cards: list[HomeMediaCard]


class AnalysisRecord(BaseModel):
    id: str
    created_at: datetime
    image_filename: str
    menu_source: Literal["url", "manual", "none"]
    menu_url: Optional[str] = None
    menu_items: list[str]
    items: list[WasteItem]
    summary: WasteSummary
    recommendations: Optional[RecommendationsResult] = None
    notes: str = ""
