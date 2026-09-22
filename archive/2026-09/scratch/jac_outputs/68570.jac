"""Get release date."""
def get_release_date(data: dict[str, str]) -> str | None {
    date = data.get("physicalRelease");
    if not date {
        date = data.get("inCinemas");
    }
    return date;
}