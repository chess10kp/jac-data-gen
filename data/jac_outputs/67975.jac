""" Helper function to objectify items """
def sanitize_list(mylist: str | None) -> list[str] | None {
    if mylist is not None {
        return mylist.split(',');
    }
    return None;
}