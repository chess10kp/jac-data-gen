"""Translate urls into human-readable filenames."""
def clean_paths(url: str) -> str {
    to_remove = ['http://', 'https://', 'www.', '.com', '.json', '.'];
    for item in to_remove {
        url = url.replace(item, '');
    }
    return url.replace('/', '_');
}