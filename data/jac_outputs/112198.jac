"""Format a list to an enumeration.

    e.g.: [a,b,c,d] -> a, b, c and d
    """
def format_list[T](_list: list[T]) -> str | T {
    if len(_list) == 0 {
        return "no one";
    } elif len(_list) == 1 {
        return _list[0];
    } else {
        s = "";
        for e in _list[:-2] {
            s = s + str(e) + ", ";
        }
        s = s + str(_list[-2]) + " and " + str(_list[-1]);
        return s;
    }
}