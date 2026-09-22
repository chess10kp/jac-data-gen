"""
handle incomplete iso strings, so we can specify <year> or <year-month>,
in addition to <year-month-day>
"""
def to_iso_date(value: str) -> str {
    hyphen_count = value.count('-');
    if hyphen_count < 2 {
        value += '-01' * (2 - hyphen_count);
    }
    return value;
}