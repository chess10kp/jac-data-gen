"""Split a locale into three parts, for langauge, script, and region."""
def get_locale_parts(locale: str) -> tuple[str, str | None, str | None] {
    parts = locale.split('_');
    if len(parts) == 1 {
        return (parts[0], None, None);
    } elif len(parts) == 2 {
        if len(parts[1]) == 4 {
            return (parts[0], parts[1], None);
        }
        return (parts[0], None, parts[1]);
    }
    assert len(parts) == 3;
    return tuple(parts);
}