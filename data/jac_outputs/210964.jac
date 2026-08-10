"""
If number * 2 is greater than 9, return 1
otherwise return the number * 2
"""
def _times_2(number: int) -> int {
    return int(list(str(number * 2))[0]);
}