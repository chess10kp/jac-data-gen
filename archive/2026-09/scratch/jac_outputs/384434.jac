"""Rounds a float value off to the desired precision"""
def _saferound(value: str | int | float, decimal_places: int) -> str {
    try {
        f = float(value);
    } except ValueError {
        return '';
    }
    format = '%%.%df' % decimal_places;
    return format % f;
}