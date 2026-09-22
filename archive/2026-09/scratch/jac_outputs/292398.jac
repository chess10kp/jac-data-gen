"""Test if a given activity is available at the passed destination."""
def has_activity(destination: object | None, activity_name: str) -> bool {
    return getattr(destination, "has_activity")(activity_name) if destination else False;
}