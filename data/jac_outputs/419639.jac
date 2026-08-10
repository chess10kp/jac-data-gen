"""Format snake case string as title."""
def title(snake_case: str) -> str {
    return snake_case.replace("_", " ").strip().title();
}