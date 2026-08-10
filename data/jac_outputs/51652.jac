"""Scrub database-specific metadata fields from a document."""
def scrub_db_specific_data(document: dict[str, str | int | float | bool | None]) -> dict[str, str | int | float | bool | None] {
    document.pop('_id', None);
    document.pop('_rev', None);
    return document;
}