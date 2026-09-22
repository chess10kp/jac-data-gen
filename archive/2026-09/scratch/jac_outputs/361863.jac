"""Return integer value representing an operator's precedence, or
order of operation.

https://en.wikipedia.org/wiki/Order_of_operations"""
def precedence(char: str) -> int {
    dictionary = {"+": 1, "-": 1, "*": 2, "/": 2, "^": 3};
    return dictionary.get(char, -1);
}