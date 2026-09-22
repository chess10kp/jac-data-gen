"""Returns the startdate from an acquired date string."""
def startdate(acquired: str) -> str {
    return acquired.split('/')[0];
}