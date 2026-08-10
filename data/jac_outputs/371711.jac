""" Return the prime factors of the given number. """
def prime_factors(n: int) -> list[int] {
    if n <= 1 {
        return [1];
    }
    factors = [];
    lastresult: float = n;
    while True {
        if lastresult == 1 {
            break;
        }
        c = 2;
        while True {
            if lastresult % c == 0 {
                break;
            }
            c += 1;
        }
        factors.append(c);
        lastresult /= c;
    }
    return factors;
}