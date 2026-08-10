"""calculate the sum of the digits of an input integer"""
def sumofDigits(n: int) -> int {
    assert n >= 0 and int(n) == n, "The number has to be positive integers only";
    if n == 0 {
        return 0;
    }
    return int(n % 10) + sumofDigits(int(n / 10));
}