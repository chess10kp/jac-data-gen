"""
Input:
    args - variable number of integers represented as strings, e.g. to_list("15353", "025")

Output:
    lst - a Python array of lists of strings, e.g. [[1,5,3,5,3],[0,2,5]]
"""
def to_list(*args: str) -> list[list[int]] {
    return [[int(digit) for digit in string] for string in args];
}