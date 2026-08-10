glob EXCLUDE_PATTERNS = [
    "mul. p",
    "mult p",
    "mult. p",
    "mult. p.",
    "mult. p",
    "multi p",
    "multi pages"
];

"""Validate if field 300 should be excluded."""
def is_excluded(value: str | None) -> bool {
    return not value or value.strip().lower() in EXCLUDE_PATTERNS;
}