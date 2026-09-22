"""Convert array to dict."""
def to_dict(arr: list[dict[str, str]] | dict[str, dict[str, str]], id_: str = 'id') -> dict[str, dict[str, str]] {
    result = {};
    if isinstance(arr, dict) {
        return arr;
    }
    for row in arr {
        result[row[id_]] = row;
    }
    return result;
}