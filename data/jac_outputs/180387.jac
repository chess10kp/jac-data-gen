"""Returns true if header (which must be lowercase) is a custom header."""
def _IsCustomMeta(header: str) -> bool {
    return header.startswith(('x-goog-meta-', 'x-amz-meta-'));
}