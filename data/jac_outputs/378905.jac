"""Find factors of num, in increasing order."""
def find_factors(num: int) -> list[int] {
    f = [1];
    for x in range(2, num) {
        if num % x == 0 {
            f.append(x);
        }
    }
    if num > 1 {
        f.append(num);
    }
    return f;
}