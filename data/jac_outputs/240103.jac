"""Build bucket path."""
def join_bucket_paths(*items: str) -> str {
    return '/'.join(item.strip('/ ') for item in items);
}