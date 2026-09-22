"""Turn empty or 'none' string to None."""
def noneorstr(s: Any) -> object {
    if (s.lower() in ('', 'none')) {
        return None;
    } else {
        return s;
    }
}