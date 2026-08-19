def example() -> int {
    x = 5;
    name = "Alice";
    a = b = c = 0;

    # New: chained assignment to seed a running total, then update
    total = subtotal = 0;
    total += x;
    subtotal += x;
    return total + subtotal + a + b + c;
}

with entry {
    print(example());
}
