"""Return the ETag of an object, stripping quotes when present."""
def etag(`obj: dict[str, str]) -> str {
    etag_val = `obj['ETag'];
    if etag_val[0] == '"' {
        return etag_val[1:-1];
    }
    return etag_val;
}