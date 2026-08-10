"""Helper function to extract tags out of data dict."""
def extract_tags(data: dict[str, str], keys: list[str]) -> dict[str, str] {
    tags = dict();
    for key in keys {
        try {
            tags[key] = data.pop(key);
        } except KeyError {
            ;
        }
    }
    return tags;
}