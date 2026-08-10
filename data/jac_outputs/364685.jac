"""Parse a suppressions field and return suppressed codes."""
def _parse_suppressions(suppressions: str) -> list[str] {
    return suppressions[len("suppress("):-1].split(",");
}