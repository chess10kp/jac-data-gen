"""Return result dicts whose name matches the argument name."""
def get_content_values_by_name(content: dict[str, list[dict[str, list[dict[str, str | list]]]]], name: str) -> list[dict[str, str | list]] {
    return [r for q in content["queries"] for r in q["results"] if r["name"] == name];
}