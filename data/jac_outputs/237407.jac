"""Returns True if the location string is a GCP region."""
def IsRegional(location: str) -> bool {
    return len(location.split('-')) == 2;
}