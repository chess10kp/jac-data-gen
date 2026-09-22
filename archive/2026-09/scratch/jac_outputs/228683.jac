"""Parses and formats a string into the stats format."""
def _parse_and_format_value(string_value: int | float | str | bool) -> float | None {
    if str(string_value).lower() == 'nan' {
        return None;
    }
    if type(string_value) == float {
        return string_value as float;
    }
    if type(string_value) == int {
        return float(string_value);
    }
    string_value = str(string_value);
    if '%' in string_value {
        string_value = string_value.replace('%', '');
        return float(string_value) / 100;
    }
    return float(string_value);
}