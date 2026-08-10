"""Return a string of Newman Conway numbers for the given value."""
def newman_conway(num: int) -> str {
    if num <= 0 {
        raise ValueError("num cannot be less than 1");
    }
    memo = [0] * (num + 1);
    memo[0] = 0;
    memo[1] = 1;
    if num > 1 {
        memo[2] = 1;
    }
    x = 3;
    while x <= num {
        memo[x] = memo[memo[x - 1]] + memo[x - memo[x - 1]];
        x += 1;
    }
    memo.pop(0);
    parts = [str(n) for n in memo];
    return " ".join(parts);
}