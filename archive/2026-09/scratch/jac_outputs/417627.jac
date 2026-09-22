"""Utility for returning the date format for a given date filter in human readable format."""
def get_date_print_format(date_filter: str) -> str {
    vals = {"day": "[YYYY-MM-DD]", "hour": "[YYYY-MM-DD : HH]"};
    return vals[date_filter];
}