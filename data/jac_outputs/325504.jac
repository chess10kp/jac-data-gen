"""Appends .json to the string SYMBOL."""
def json_filename(symbol: str) -> str {
    return f"stockJSON/{symbol}.json";
}