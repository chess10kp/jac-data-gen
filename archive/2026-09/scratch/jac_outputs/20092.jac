""" Returns a list of the Newman Conway numbers for the given value.
        Time Complexity: ?
        Space Complexity: ?
    """
def newman_conway(num: int) -> str {
    if num == 0 {
        raise ValueError;
    }
    arr = [0, 1, 1];
    for i in range(3, num + 1) {
        r = arr[arr[i - 1]] + arr[i - arr[i - 1]];
        arr.append(r);
    }
    ' '.join([str(n) for n in arr[1:]])
}