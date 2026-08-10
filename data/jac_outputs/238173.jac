"""Return True if the given string is a search key."""
def is_search(splunk_record_key: str) -> bool {
    return splunk_record_key == 'search';
}