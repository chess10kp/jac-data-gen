"""Returns a list of primes from 2 to 'upper'"""
def prime_sieve(upper: int, lower: int = 2) -> list[int] {
    if lower < 2 {
        raise ValueError("Lower bound cannot be lower than 2");
    }
    prime_list = list(range(lower, upper));
    index = 0;
    while True {
        try {
            prime = prime_list[index];
            for i in prime_list[index + 1:] {
                if i % prime == 0 {
                    prime_list.remove(i);
                }
            }
        } except IndexError {
            break;
        }
        index += 1;
    }
    return prime_list;
}