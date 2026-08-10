"""Creates and returns an S3 key for the message."""
def get_target_key(
    stream_name: str,
    object_format: str,
    key_stem: str,
    prefix: str = "",
    naming_convention: str | None = None
) -> str {
    return f"{prefix}{stream_name}/{key_stem}.{object_format}";
}