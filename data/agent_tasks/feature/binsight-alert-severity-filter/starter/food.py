import anthropic
import base64
import json
import sys
from pathlib import Path

client = anthropic.Anthropic()  # set ANTHROPIC_API_KEY env var

BASE_SYSTEM_PROMPT = """You are a food waste analysis system for university dining halls.
Given an image of a trash can or food waste, analyze it and respond ONLY with valid JSON (no markdown, no backticks) in this exact format:

{
  "items": [
    {
      "food": "name of food item",
      "category": "protein" | "grain" | "dairy" | "fruit" | "vegetable" | "beverage" | "other",
      "estimated_weight_oz": number,
      "estimated_portion_wasted_pct": number (0-100),
      "estimated_cost_usd": number
    }
  ],
  "summary": {
    "total_items": number,
    "total_estimated_weight_oz": number,
    "total_estimated_cost_usd": number,
    "most_wasted_category": "string",
    "waste_severity": "low" | "medium" | "high" | "critical"
  },
  "recommendations": ["actionable suggestion 1", "suggestion 2", "suggestion 3"],
  "notes": "any relevant observations about the waste pattern"
}

Be specific about food items. Estimate weights and costs based on typical US dining hall pricing.
If the image is unclear, do your best and note uncertainty in the notes field."""


def build_system_prompt(menu_items: list[str] | None) -> str:
    if not menu_items:
        return BASE_SYSTEM_PROMPT
    menu_list = "\n".join(f"  - {item}" for item in menu_items)
    return BASE_SYSTEM_PROMPT + f"""

IMPORTANT: Only classify food waste using items from today's menu below. If something in the image does not match a menu item, use the closest match or mark it as "other" in the notes.

Today's menu:
{menu_list}"""


def load_menu(menu_path: str) -> list[str]:
    """Load menu items from a text file (one item per line)."""
    lines = Path(menu_path).read_text().splitlines()
    return [line.strip() for line in lines if line.strip()]


def encode_image(image_path: str) -> tuple[str, str]:
    """Read and base64-encode an image file."""
    path = Path(image_path)
    suffix = path.suffix.lower()
    media_types = {
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".png": "image/png",
        ".gif": "image/gif",
        ".webp": "image/webp",
    }
    media_type = media_types.get(suffix, "image/jpeg")
    data = base64.standard_b64encode(path.read_bytes()).decode("utf-8")
    return data, media_type


def analyze_waste(image_path: str, menu_items: list[str] | None = None) -> dict:
    """Send a trash can image to Claude and get structured waste analysis."""
    image_data, media_type = encode_image(image_path)
    system_prompt = build_system_prompt(menu_items)

    message = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=1500,
        system=system_prompt,
        messages=[
            {
                "role": "user",
                "content": [
                    {
                        "type": "image",
                        "source": {
                            "type": "base64",
                            "media_type": media_type,
                            "data": image_data,
                        },
                    },
                    {
                        "type": "text",
                        "text": "Analyze the food waste in this image.",
                    },
                ],
            }
        ],
    )

    raw = message.content[0].text
    return json.loads(raw)


def print_report(analysis: dict):
    """Pretty-print the waste analysis."""
    s = analysis["summary"]

    print("\n" + "=" * 50)
    print("  FOOD WASTE ANALYSIS REPORT")
    print("=" * 50)

    print(f"\n{'Items found:':<30} {s['total_items']}")
    print(f"{'Total weight:':<30} {s['total_estimated_weight_oz']:.1f} oz")
    print(f"{'Estimated cost wasted:':<30} ${s['total_estimated_cost_usd']:.2f}")
    print(f"{'Most wasted category:':<30} {s['most_wasted_category']}")
    print(f"{'Waste severity:':<30} {s['waste_severity'].upper()}")

    print("\n--- Items Detected ---")
    for item in analysis["items"]:
        print(f"  • {item['food']:<25} {item['estimated_weight_oz']:>5.1f} oz"
              f"  (~${item['estimated_cost_usd']:.2f})"
              f"  [{item['category']}]")

    print("\n--- Recommendations ---")
    for i, rec in enumerate(analysis["recommendations"], 1):
        print(f"  {i}. {rec}")

    if analysis.get("notes"):
        print(f"\nNotes: {analysis['notes']}")

    print()


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python food.py <image_path> [menu_file]")
        print("  e.g. python food.py trash_photo.jpg menu.txt")
        sys.exit(1)

    image_path = sys.argv[1]
    if not Path(image_path).exists():
        print(f"Error: file not found: {image_path}")
        sys.exit(1)

    menu_items = None
    if len(sys.argv) >= 3:
        menu_path = sys.argv[2]
        if not Path(menu_path).exists():
            print(f"Error: menu file not found: {menu_path}")
            sys.exit(1)
        menu_items = load_menu(menu_path)
        print(f"Loaded {len(menu_items)} menu items from {menu_path}")

    print(f"Analyzing: {image_path} ...")
    result = analyze_waste(image_path, menu_items)
    print_report(result)

    # also dump raw JSON for downstream use
    out = Path("waste_analysis.json")
    out.write_text(json.dumps(result, indent=2))
    print(f"Raw JSON saved to {out}")