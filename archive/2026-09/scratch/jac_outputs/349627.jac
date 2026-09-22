"""
    If two numbers can be summed in a needed way.

    Examples
    -----
    9000 80 -> True (9080)
    20 30 -> False (20 30)
    1 2 -> False (1 2)
    2 1 -> False (2 1)
    20 1 -> True (21)
    -----
    """
def is_summable(num1: Any, num2: Any) -> object {
    if ((num1 == 10) or (num2 == 0)) {
        return False;
    }
    place = len(str(num2));
    str1 = str(num1);
    if ((len(str1) > place) and (str1[-place] == "0")) {
        return True;
    }
    return False;
}