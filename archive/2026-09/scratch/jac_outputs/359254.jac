"""Remove suffix frm the end of s."""
def strip_suffix(s: str | int | float | bool | list | dict | None, suffix: str | int | float | bool | list | dict | None) -> str | None {
    if not isinstance(s, str) {
        return None;
    }
    if not isinstance(suffix, str) {
        return s;
    }
    if s.endswith(suffix) {
        return s[:-len(suffix)];
    }
    return s;
}