"""
    zero_prefix_number(int) -> str\n
    Puts a zero in fron of 1 digit numbers.\n
    otherwise just returns the int
    """
def zero_prefix_int(num: int) -> str {
    strnum = str(num);
    if len(strnum) == 1 {
        return '0' + strnum;
    }
    return strnum;
}