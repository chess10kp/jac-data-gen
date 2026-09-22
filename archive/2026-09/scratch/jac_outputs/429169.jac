"""Returns true if the first word in status is 'select'."""
def is_select(status: Any) -> object {
    if not status {
        return False;
    }
    return (status.split(None, 1)[0].lower() == "select");
}