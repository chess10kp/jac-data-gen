"""
    Write a function, persistence, that takes in a positive parameter num and returns its multiplicative persistence,
    which is the number of times you must multiply the digits in num until you reach a single digit.
    """
def persistence(n: int) -> int {
    if n < 10 {
        return 0;
    }
    total = 1;
    for i in str(n) {
        total = total * int(i);
    }
    return 1 + persistence(total);
}