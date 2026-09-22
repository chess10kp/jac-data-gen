"""
Convert value into a format that will be understood by Munin
"""
def format_value_for_munin(value: int | float | str | None, zero_allowed: bool = False) -> int | float | str {
    return value if value or (zero_allowed and value == 0) else 'U';
}