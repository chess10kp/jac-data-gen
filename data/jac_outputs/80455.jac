"""function helper for fourth Euler problem."""
def is_palindrome(n: int) -> bool {
    rn = 0;
    on = n;
    while n != 0 {
        remainder = int(n % 10);
        rn = rn * 10 + remainder;
        n = int(n / 10);
    }
    return on == rn;
}