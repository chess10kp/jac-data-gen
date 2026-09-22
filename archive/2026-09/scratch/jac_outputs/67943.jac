"""takes in a positive n and returns the multiplicative persistence"""
def persistence(n: int) -> int {
    count = 0;
    if len(str(n)) == 0 {
        return 0;
    }
    while len(str(n)) > 1 {
        p = 1;
        for i in str(n) {
            p *= int(i);
        }
        n = p;
        count += 1;
    }
    return count;
}