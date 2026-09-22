"""Converts to a list, safely."""
def ensure_list(var: str | list[str]) -> list[str] {
    if isinstance(var, str) {
        return [var];
    }
    return var;
}