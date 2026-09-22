"""Gets the first num keywords of line"""
def _get_keywords(line: Any, num: Any = 2) -> object {
    return line.lower().split(None, num);
}