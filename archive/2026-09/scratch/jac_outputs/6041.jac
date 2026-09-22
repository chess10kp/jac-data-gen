"""
    Args:
        Rangelist: generic list of tuples (can be either float or int tuple)
    Return:
        Reduced int list based on average value of every tuple in input tuple list
    """
def reduce(l: Any) -> object {
    result = [];
    for s in l {
        midVal = abs((float(s[0]) - float(s[1]))) / 2.0;
        result.append(midVal);
    }
    return result;
}