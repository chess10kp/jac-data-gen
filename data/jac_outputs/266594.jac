"""Return the prime factorization of `n`."""
def prime_factorization(n: float) -> dict[int, int] {
    prime_factors: dict[int, int] = {};
    i = 2;
    while i ** 2 <= n {
        if n % i {
            i += 1;
        } else {
            n /= i;
            try {
                prime_factors[i] += 1;
            } except KeyError {
                prime_factors[i] = 1;
            }
        }
    }
    if n > 1 {
        try {
            prime_factors[n] += 1;
        } except KeyError {
            prime_factors[n] = 1;
        }
    }
    return prime_factors;
}