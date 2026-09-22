"""Pluralize a noun."""
def pluralize(value: int, noun: str) -> str {
    nouns = {"success": "successes", "die": "dice"};
    pluralized = f"{value} {noun}";
    if value != 1 {
        if noun in nouns {
            pluralized = f"{value} {nouns[noun]}";
        } else {
            pluralized += "s";
        }
    }
    return pluralized;
}