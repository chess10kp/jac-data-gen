"""
    Check if a file contains one or many of the substrings specified in filters
    """
def contain_filter(file: str, filters: list[str] | None = None) -> bool {
    if filters is None {
        return True;
    }
    any(len(file.split(f)) >= 2 for f in filters)
}