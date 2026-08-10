"""Convert Python format date to human (e.g. '%Y-%m-%d' -> 'YYYY-MM-DD')."""
def date_format_to_human(value: str) -> str {
    maps = {'%y': 'YY', '%Y': 'YYYY', '%m': 'MM', '%d': 'DD'};
    for (k, v) in maps.items() {
        value = value.replace(k, v);
    }
    return value;
}