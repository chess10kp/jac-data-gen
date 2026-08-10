"""Cleans the given file format string"""
def _clean_archive_file_format(fmt: str) -> str {
    return fmt.lower().strip('.').strip(':');
}