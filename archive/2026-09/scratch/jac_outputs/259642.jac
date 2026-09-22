"""Split snake_case funtion names to tokens."""
def snake_case_split(identifier: str) -> list[str] {
    return [token.lower() for token in identifier.split('_')];
}