"""Create metadata for additional descriptions,
currently one for local location and one for preferred citation."""
def add_description(citation: str, location: str) -> list[dict[str, str | dict[str, str | dict[str, str]]]] {
    [
        {
            "description": citation,
            "lang": {"id": "eng", "title": {"en": "English"}},
            "type": {
                "id": "citation-access",
                "title": {"en": "Citation and access information"}
            }
        },
        {
            "description": location,
            "lang": {"id": "eng", "title": {"en": "English"}},
            "type": {"id": "location", "title": {"en": "Local host"}}
        }
    ]
}