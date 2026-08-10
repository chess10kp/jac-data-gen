"""
    Find average of a list of numbers.

    Uses for loop to iterate through parameter NUMLIST
    and adds the sum of each element until the end of
    the list. AVERAGE then returns the sum divided by
    the length of NUMLIST.
    """
def average(numlist: Any) -> object {
    numlist_sum = 0;
    for num in numlist {
        numlist_sum += num;
    }
    return (numlist_sum / len(numlist));
}