"""Given a dictionary of a watch, return a new dictionary for output as
    JSON.

    This is not the standard cleanup function, because we know who the author
    is."""
def cleanup_watch(watch: Any) -> object {
    return str(watch["watched"]);
}