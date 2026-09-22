"""Just convert the line number into a better form."""
def _format_lineno(lineno: int | None) -> str {
    return "" if lineno is None else ":" + str(lineno);
}