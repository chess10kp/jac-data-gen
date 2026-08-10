""" Given a list of names, some of the names can be comma-separated lists.
        Return a new list of single names (names in comma-separated lists are
        spliced into the list).
    """
def _splice_comma_names(namelist: Any) -> object {
    newlist = [];
    for name in namelist {
        if (',' in name) {
            newlist.extend(name.split(','));
        } else {
            newlist.append(name);
        }
    }
    return newlist;
}