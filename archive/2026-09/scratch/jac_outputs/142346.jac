"""Builds the name of an archive file for a software release."""
def _build_archive_name(software: str, version: str, extension: str) -> str {
    return f"{software}-{version}{extension}";
}