"""Return dict rows with keys and values converted to Unicode strings."""
def get_unicode_dicts(iterable: Iterable[dict[int | str, int | str | None]]) -> list[dict[str, str | None]] {
    def none_or_unicode(val: int | str | None) -> str | None {
        return str(val) if val is not None else val;
    }
    return [{str(k): none_or_unicode(v) for (k, v) in row.items()} for row in iterable];
}