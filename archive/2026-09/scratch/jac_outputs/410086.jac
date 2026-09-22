"""
    Given a sponsorid, find the org with that sponsor.  Return True and URI
    if found.  Return false and None if not found
    """
def find_sponsor(sponsorid: Any, sponsor_dictionary: Any) -> object {
    try {
        uri = sponsor_dictionary[sponsorid];
        found = True;
    } except Exception as e {
        uri = None;
        found = False;
    }
    return [found, uri];
}