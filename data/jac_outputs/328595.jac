"""Function which strips a trailing slash from the provided url if one is present."""
def get_url_without_trailing_slash(value: str) -> str {
    value[:-1] if value.endswith('/') else value
}