"""Problem solution."""
def beautifulDays(i: int, j: int, k: int) -> int {
    def reverse(n: int) -> int {
        int(str(n)[::-1])
    }
    c = 0;
    for day in range(i, j + 1) {
        if (day - reverse(day)) % k == 0 {
            c += 1;
        }
    }
    c
}