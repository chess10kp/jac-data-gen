"""Sort by downloads."""
def _sort(data: list[dict[str, int | str]] | dict[str, int | str]) -> list[dict[str, int | str]] | dict[str, int | str] {
    if isinstance(data, dict) {
        return data;
    }
    return sorted(data, key=lambda (k: dict[str, int | str]) { k["downloads"]; }, reverse=True);
}