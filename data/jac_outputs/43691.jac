"""Return the largest digit in the number."""
def find_largest_digit(n: float) -> int | None {
    if n < 0 {
        return find_largest_digit(n * -1);
    } elif n < 10 {
        return int(n);
    } elif n % 100 > 0 and n % 10 > 0 {
        if (n % 10) * 10 >= n % 100 {
            m = (n - n % 100) / 10 + n % 10;
            return find_largest_digit(m);
        }
        m = (n - n % 10) / 10;
        return find_largest_digit(m);
    }
}