def add(a: int, b: int) -> int {
    return a + b;
}

def power(base: int, exp: int) -> int {
    return base ** exp;
}

with entry {
    print(add(2, 3));
    print(power(2, 3));
}
