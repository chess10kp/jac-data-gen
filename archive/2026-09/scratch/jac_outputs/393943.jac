"""Returns period of 1/n."""
def getPeriod(n: int) -> int {
    if n != int(n) or n < 1 {
        raise ValueError("n must be positive integer");
    }
    rem = 1;
    for i in range(1, n + 2) {
        rem = (10 * rem) % n;
    }
    d = rem;
    count = 0;
    rem = (10 * rem) % n;
    count += 1;
    while rem != d {
        rem = (10 * rem) % n;
        count += 1;
    }
    return count;
}