"""Determine if there are many items in the text."""
def is_single(text: str) -> bool {
    indicators = [', ', ' y ', ' e '];
    return not any(ind in text for ind in indicators);
}