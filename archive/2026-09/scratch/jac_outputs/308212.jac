"""Construct the url suitable for scraping a given measure."""
def measure_url(n: int) -> str {
    return f'https://www.ats.aq/devAS/Meetings/Measure/{n}';
}