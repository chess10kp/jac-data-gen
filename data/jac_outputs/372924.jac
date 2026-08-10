"""
    Parameters
    ----------
    string String representation of a list

    Returns A List
    -------

    """
def str_to_list(string: Any) -> object {
    if ("[" and ("]" in string)) {
        string = string[1:-1];
        spt = string.split(",");
        lis = [];
        for f in spt {
            lis.append(float(f));
        }
        return lis;
    }
    return [];
}