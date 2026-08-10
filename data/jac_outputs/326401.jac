"""Extract ID from the end of the URI."""
def extract_id_from_uri(id_or_uri: str) -> str {
    if '/' in id_or_uri {
        return id_or_uri[id_or_uri.rindex('/') + 1:];
    }
    return id_or_uri;
}