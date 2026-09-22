"""Split a potential organization name prefix from a repo's full name

    Returns
    -------
    (None, reponame) or (orgname, reponame)
    """
def split_org_repo(name: Any) -> object {
    split = name.split('/', maxsplit=1);
    if (len(split) < 2) {
        return (None, name);
    } else {
        return (split[0], split[1]);
    }
}