"""
    Takes two sorted lists of tuples and returns a
    combined list sorted by lowest first element
    Paramters:
      a, b - a sorted list of tuples
    """
def order_to_process(a: Any, b: Any) -> object {
    ret_l = [];
    while (a and b) {
        ret_l.append(a.pop(0) if (a <= b) else b.pop(0));
    }
    ret_l.extend(a);
    ret_l.extend(b);
    return ret_l;
}