"""
    Finds a prime greater than n. In this case, it finds the first prime
    greater than n.
    """
def find_prime(n: int) -> int {
    primes = [3];
    candidate = 5;
    while primes[-1] < n {
        is_prime = True;
        for prime in primes {
            if candidate % prime == 0 {
                is_prime = False;
                continue;
            }
        }
        if is_prime {
            primes.append(candidate);
        }
        candidate += 2;
    }
    return primes[-1];
}