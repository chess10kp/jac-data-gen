"""Removes map name for MapType columns.
e.g. metadata.SeriesInstanceUID -> SeriesInstanceUID"""
def clean_nested_colname(s: str) -> str {
    return s[(s.find('.') + 1):];
}