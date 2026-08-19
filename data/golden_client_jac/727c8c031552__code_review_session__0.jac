def square(x: int) -> int {
    return x * x;
}

with entry {
    n = 5;
    print(f"{n}^2 = {square(n)}");
}
