"""Determine whether a particular item should be exported as part of this export run."""
def skipExport(
    item: dict[str, dict[str, str | bool | int | float | None]],
    all: bool,
    metadataProperty: str
) -> bool | str | int | float | None {
    return not all and item.get('meta', {}).get(metadataProperty);
}