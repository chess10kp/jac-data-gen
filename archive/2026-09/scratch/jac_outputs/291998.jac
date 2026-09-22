"""Helper to provide a key function for `sorted`

    Provide key to sort by type first and by whatever identifies a particular
    type of spec dict
    """
def sort_spec(spec: dict[str, str]) -> str {
    if spec['type'] == 'dicomseries' {
        return 'dicomseries' + spec['uid'];
    }
    return spec['type'] + spec['location'];
}