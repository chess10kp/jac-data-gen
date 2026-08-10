"""Format a date string for Cisco Email security (YYYY-MM-DDThh:mm:ss.000Z)."""
def date_to_cisco_date(date: str) -> str {
    return date.replace(' ', 'T') + '.000Z';
}