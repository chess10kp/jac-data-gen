"""Numeric factorization for a fibonacci number."""
def factorization(fib: int) -> list[str] {
    print(f"initializing factorization for {fib}");
    divisor = 2;
    values: list[str] = [];
    if fib <= 5 {
        values.append(str(fib));
    } else {
        n: int | float = fib;
        while n != 1 {
            if n % divisor == 0 {
                values.append(str(divisor));
                n = n / divisor;
            } else {
                divisor += 1;
            }
        }
    }
    return values;
}