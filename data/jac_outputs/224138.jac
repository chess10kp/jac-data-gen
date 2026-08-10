"""Parse date string to (yyyy, MM, dd)."""
def parse_date(d: str) -> tuple[int, int, int] | None {
    date_fields = d.split('-');
    if date_fields and len(date_fields) == 3 {
        return (int(date_fields[0]), int(date_fields[1]), int(date_fields[2]));
    }
    return None;
}