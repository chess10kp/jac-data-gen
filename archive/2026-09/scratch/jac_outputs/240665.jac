"""
    Normalize the grant and/or revoke lists we were given. Handle single item, list of items, etc.
    We want to end up with just a list of IDs. Used by Project object to handle modify_access function.

    :param acl: a list of Person objects or just a Person object
    :return: a list of integers representing the IDs of the Person objects in the list given
    """
def normalize_acl(acl: Any) -> object {
    try {
        acl = [int(a) for a in acl];
    } except TypeError {
        acl = [int(acl)];
    }
    return acl;
}