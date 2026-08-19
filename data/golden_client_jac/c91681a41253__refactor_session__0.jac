def basics() -> None {
    sum = 5 + 3;
    product = 6 * 7;
    print(sum);
    print(product);
}

def combined() -> int {
    return (5 + 3) * 2;
}

with entry {
    basics();
    print(combined());
}
