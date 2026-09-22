"""Formats a number into a percentage string."""
def format_percentage(number: float) -> str {
    return '{}%'.format(round(number * 100));
}