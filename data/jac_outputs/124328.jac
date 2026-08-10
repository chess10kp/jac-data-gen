"""Generate url from position and location."""
def get_url(position: str, location: str) -> str {
    return 'https://nz.indeed.com/jobs?q={}&l={}'.format(position, location);
}