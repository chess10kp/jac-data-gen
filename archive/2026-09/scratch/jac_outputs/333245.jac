"""Leave only needed fields from the response."""
def clean_item(
    item: dict[str, str | dict[str, str]],
    artist: dict[str, str],
    languages: str
) -> dict[str, str | dict[str, str]] {
    return {
        "id": item["id"],
        "danceStyle": item["fields"]["Name"],
        "dateTime": item["fields"]["DateTime(GMT)"],
        "artists": artist,
        "language": languages
    };
}