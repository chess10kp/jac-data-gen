"""Converts year from number to string in yyyy format."""
def _year_number_to_string(year: int) -> str {
    '{0:04d}'.format(int(year))
}