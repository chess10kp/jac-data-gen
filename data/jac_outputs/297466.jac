"""Helper function to convert strings to int or floats.
    Input: string
    Output: Int, Float or String if non convertable.
    """
def number(string: str) -> int | float | str {
    try {
        return int(string);
    } except TypeError {
        return float(string);
    } except ValueError {
        return string;
    }
}