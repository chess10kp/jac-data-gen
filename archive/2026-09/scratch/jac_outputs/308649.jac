"""
    parse numeric values
    """
def parse_number(key: str, string: str) -> float {
    size = string.split(", ")[0].replace("px", "");
    return float(size);
}