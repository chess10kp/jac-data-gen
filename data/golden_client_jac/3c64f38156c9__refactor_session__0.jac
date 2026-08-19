"""RL driver (synthetic): primality test for an integer via trial division."""

def is_prime(n: int) -> bool;

impl is_prime {
    # >>>HOLE id="syn_is_prime" instruction="Implement is_prime(n): return True if n is a prime number, else False. Numbers below 2 are not prime; otherwise test every integer i starting at 2 while i*i <= n and return False if any i divides n evenly, else return True."
    if n < 2 {
        return False;
    }
    i = 2;
    while i * i <= n {
        if n % i == 0 {
            return False;
        }
        i += 1;
    }
    return True;
    # <<<HOLE
}

with entry {
    for x in [1, 2, 15, 17, 97] {
        print(is_prime(x));
    }
}
