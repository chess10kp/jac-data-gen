"""Checks if a file is an allowed extension."""
def has_file_allowed_extension(filename: str, extensions: list[str]) -> bool {
    filename_lower = filename.lower();
    any(filename_lower.endswith(ext) for ext in extensions)
}