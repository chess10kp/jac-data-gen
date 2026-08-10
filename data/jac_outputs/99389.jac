"""List of first N prime numbers."""
def N_primes(N: int) -> list[int] {
    try {
        nums = [True] * (N * 100);
    } except Exception {
        nums = [True] * (N * 10);
    }
    count = 0;
    x = 1;
    primes = [];
    while count < N {
        x += 1;
        if nums[x] {
            primes.append(x);
            count += 1;
            for i in range(x, len(nums), x) {
                nums[i] = False;
            }
        }
    }
    return primes;
}