def is_armstrong(n: int) -> bool {
    digits = str(n);
    power = len(digits);
    return n == sum([int(d) ** power for d in digits]);
}

with entry {
    print(is_armstrong(153));
}
