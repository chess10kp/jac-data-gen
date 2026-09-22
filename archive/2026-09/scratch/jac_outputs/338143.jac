"""
    Return list of n empty lists.
    """
def make_null_array(n: Any) -> object {
    a = [];
    for i in range(n) {
        a.append([]);
    }
    return a;
}