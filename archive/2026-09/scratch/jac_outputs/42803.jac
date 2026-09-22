"""Return True if the list is a palindrome; False otherwise."""
def isPal(x: list[str | int | float | bool]) -> bool {
    temp = x[:];
    temp.reverse();
    return temp == x;
}