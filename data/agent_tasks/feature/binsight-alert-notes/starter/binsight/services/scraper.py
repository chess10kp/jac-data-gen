import re
from typing import Literal

import requests
from bs4 import BeautifulSoup

ScrapeConfidence = Literal["high", "medium", "low"]

MEAL_PERIODS = ("Breakfast", "Brunch", "Lunch", "Dinner", "Late Night")

# Lines that are nutrition/fact data, not menu item names.
_NUTRITION_LINE = re.compile(
    r"^\s*("
    r"\d+\s*(mg|g|kcal|cal|oz)\b"
    r"|saturated fat\b"
    r"|trans fat\b"
    r"|total fat\b"
    r"|cholesterol\b"
    r"|sodium\b"
    r"|total carbohydrate\b"
    r"|dietary fiber\b"
    r"|sugars?\s+\d"
    r"|protein\b"
    r"|vitamin [ac]\b"
    r"|calcium\b"
    r"|iron\b"
    r"|calories\b"
    r"|serving size\b"
    r"|amount per serving\b"
    r"|% daily value"
    r"|contains:?\s*$"
    r"|nutrient dense\b"
    r"|carbon footprint\b"
    r"|cookie\s*\(\d+g\)"
    r"|muffin\s*\(\d+g\)"
    r")",
    re.IGNORECASE,
)

# Structural sections / navigation / preference labels we never want as menu items.
_STRUCTURAL_PHRASES = {
    "menu", "m gifts", "leaps program", "dining halls", "cafés", "cafes",
    "markets", "michigan bakery", "special diets", "clear all", "allergens",
    "preferences", "build your own menus", "you have customized your menu",
    "key", "order now!", "order now", "beef", "eggs", "fish", "milk", "oats",
    "peanuts", "pork", "sesame seed", "shellfish", "soy", "tree nuts",
    "wheat/barley/rye", "item is deep fried", "alcohol", "gluten free",
    "halal", "spicy", "vegan", "vegetarian", "kosher", "feel better meals",
    "east quad", "mosher-jordan", "north quad", "south quad",
    "wolverine village", "petrovich family grill", "bursley", "markley",
    "twigs at oxford", "comments & suggestions", "contact us", "u-m home",
    "visit get", "student employment", "report an allergen incident",
    "menus & locations", "meal plans & visitors", "about us",
    "regular hours", "select access", "carbon impact and mhealthy icons",
    "today's hours", "today’s hours",
}

# Specific station/section headers that appear in the menu flow but aren't dishes.
_STATION_HEADERS = {
    "hot cereal", "salad bar", "soup", "24 carrots", "pizziti", "mbakery",
    "signature maize", "grill", "global kitchen", "deli", "dessert",
    "beverages", "two oceans", "halal", "the bowl", "maize & blue deli",
}

# Case-insensitive single words that are real foods and should pass even if
# they look "plain" (single-word titles).
_SINGLE_WORD_FOODS = {
    "oatmeal", "toast", "hummus", "quinoa", "pizziti",
}

_FOOTER_START_PHRASES = {
    "comments & suggestions",
    "contact us",
    "u-m home",
    "visit get",
    "student employment",
    "report an allergen incident",
    "menus & locations",
    "meal plans & visitors",
    "about us",
    "regular hours",
    "select access",
    "carbon impact and mhealthy icons",
    "today's hours",
    "today’s hours",
}


def scrape_menu(url: str) -> tuple[list[str], ScrapeConfidence, dict[str, list[dict]]]:
    """
    Scrape menu items from a dining hall URL.

    Returns (items, confidence, grouped) where:
      - items      is the flat deduplicated list of food names
      - confidence is "high" | "medium" | "low" based on extraction quality
      - grouped    maps meal period label -> list of {"name", "nutrition"} dicts,
                   where nutrition is a list of raw nutrition lines that followed
                   that item in the scraped page text.
    """
    if not url:
        return [], "low", {}

    try:
        resp = requests.get(
            url,
            timeout=10,
            headers={
                "User-Agent": (
                    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                    "AppleWebKit/537.36 (KHTML, like Gecko) "
                    "Chrome/120.0.0.0 Safari/537.36"
                )
            },
        )
        resp.raise_for_status()
    except requests.RequestException as e:
        raise RuntimeError(f"Failed to fetch URL: {e}") from e

    soup = BeautifulSoup(resp.text, "html.parser")
    text = soup.get_text(separator="\n", strip=True)

    raw_lines = [line.strip() for line in text.splitlines() if line.strip()]

    # Walk through the text line-by-line. Food item names alternate with
    # nutrition data; we accumulate nutrition lines onto the most recent item.
    grouped: dict[str, list[dict]] = {}
    current_period = "Menu"
    seen_global: set[str] = set()
    flat: list[str] = []
    current_item: dict | None = None

    for line in raw_lines:
        normalized = _normalize_text(line)
        if not normalized:
            continue

        if _is_footer_start(normalized) and flat:
            break

        if _is_meal_period_header(normalized):
            current_period = _canonicalize_period(normalized)
            grouped.setdefault(current_period, [])
            current_item = None
            continue

        if _is_nutrition_line(normalized):
            if current_item is not None:
                current_item["nutrition"].append(normalized)
            continue

        if not _is_menu_item(normalized):
            current_item = None
            continue

        key = normalized.lower()
        if key in seen_global:
            current_item = None
            continue
        seen_global.add(key)
        current_item = {"name": normalized, "nutrition": []}
        grouped.setdefault(current_period, []).append(current_item)
        flat.append(normalized)

    # Collapse duplicate nutrition lines per item while preserving order.
    for items in grouped.values():
        for item in items:
            seen_n: set[str] = set()
            deduped: list[str] = []
            for n in item["nutrition"]:
                k = n.lower()
                if k in seen_n:
                    continue
                seen_n.add(k)
                deduped.append(n)
            item["nutrition"] = deduped

    # Drop empty groups.
    grouped = {period: items for period, items in grouped.items() if items}

    # Confidence: high if we found multiple meal periods, medium if just one, low if none.
    period_count = sum(1 for p in grouped if p in MEAL_PERIODS)
    if period_count >= 2 and len(flat) >= 8:
        confidence: ScrapeConfidence = "high"
    elif len(flat) >= 5:
        confidence = "medium"
    else:
        confidence = "low"

    return flat, confidence, grouped


def normalize_manual_menu_items(menu_text: str) -> list[str]:
    """Clean pasted/manual menu text before it becomes LLM context."""
    items: list[str] = []
    seen: set[str] = set()

    for raw_line in menu_text.splitlines():
        line = _normalize_text(raw_line)
        if not line:
            continue

        if _is_footer_start(line) or _is_meal_period_header(line) or _is_nutrition_line(line):
            continue

        lower = line.lower()
        if lower in _STRUCTURAL_PHRASES or lower in _STATION_HEADERS:
            continue
        if _is_dining_metadata_line(line):
            continue

        if lower in seen:
            continue
        seen.add(lower)
        items.append(line)

    return items


def _normalize_text(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip(" -•\t*")


def _is_meal_period_header(text: str) -> bool:
    lower = text.lower().rstrip(":")
    return lower in {p.lower() for p in MEAL_PERIODS}


def _is_nutrition_line(text: str) -> bool:
    """Return True if this line looks like nutrition data we want to KEEP
    and attach to the current item (not reject outright)."""
    if not text:
        return False
    lower = text.lower()
    # Bare number + unit like "389mg", "24g", "0mg"
    if re.fullmatch(r"\d+(\.\d+)?\s*(mg|g|kcal|cal|oz|ml|l)", lower):
        return True
    # Nutrition label lines like "Saturated Fat 13g", "Sugars 31g", "Dietary Fiber 5g"
    if _NUTRITION_LINE.match(text):
        return True
    return False


def _is_footer_start(text: str) -> bool:
    lower = text.lower()
    if lower in _FOOTER_START_PHRASES:
        return True
    if re.search(r"\bann arbor,\s*mi\b", lower):
        return True
    if re.search(r"\b\d{3,5}\s+[\w.'-]+(?:\s+[\w.'-]+){0,4}\s+(street|st|avenue|ave|road|rd|drive|dr)\b", lower):
        return True
    return False


def _is_dining_metadata_line(text: str) -> bool:
    lower = text.lower()
    metadata_terms = (
        "nutrient dense",
        "carbon footprint",
        "vegan",
        "vegetarian",
        "gluten free",
        "halal",
        "kosher",
        "mhealthy",
    )
    return any(term in lower for term in metadata_terms) and not _is_menu_item(text)


def _canonicalize_period(text: str) -> str:
    lower = text.lower().rstrip(":")
    for period in MEAL_PERIODS:
        if period.lower() == lower:
            return period
    return text


def _is_menu_item(text: str) -> bool:
    if not text:
        return False
    if len(text) < 3 or len(text) > 80:
        return False

    lower = text.lower()

    # Drop nutrition and structural chrome.
    if _NUTRITION_LINE.match(text):
        return False
    if lower in _STRUCTURAL_PHRASES:
        return False
    if lower in _STATION_HEADERS:
        return False

    # Reject lines that are essentially just a number + unit ("24g", "389mg").
    if re.fullmatch(r"\d+(\.\d+)?\s*(mg|g|kcal|cal|oz|ml|l)", lower):
        return False
    # Reject bare numbers.
    if re.fullmatch(r"\d+(\.\d+)?", lower):
        return False
    if re.search(r"\bann arbor,\s*mi\b", lower):
        return False
    if re.search(r"\b\d{3,5}\s+[\w.'-]+(?:\s+[\w.'-]+){0,4}\s+(street|st|avenue|ave|road|rd|drive|dr)\b", lower):
        return False

    # Reject URL fragments / contact info.
    if any(token in text for token in ["©", "http", "@", "→", "|"]):
        return False

    words = text.split()
    if len(words) > 10:
        return False

    alpha_words = [word for word in words if re.search(r"[A-Za-z]", word)]
    if not alpha_words:
        return False

    # Single-word items: only allow known foods or clearly food-like stems.
    if len(alpha_words) == 1:
        single = alpha_words[0].lower().rstrip(",.:;")
        if single in _SINGLE_WORD_FOODS:
            return True
        # Short single words like "Beef" could be allergen labels already filtered,
        # but allow food-like suffixes.
        if single.endswith(("soup", "pizza", "salad", "cake", "pie", "rice", "bread", "cookies", "muffins")):
            return True
        return False

    if text.isupper() and len(words) > 3:
        return False

    # Mostly title-cased phrases look like menu items.
    looks_like_title = all(
        word[:1].isupper() or word[:1].isdigit() or word.lower() in {"w/", "and", "with", "of", "the", "a", "an", "in", "on"}
        for word in alpha_words
    )
    return looks_like_title
