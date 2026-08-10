"""Recursively find the largest digit in a number."""
def find_largest_digit_helper(n: int, lar: int) -> int {
    if n < lar {
        return lar;
    }
    if n % 10 > lar {
        lar = n % 10;
    }
    return find_largest_digit_helper(int(n / 10), lar);
}