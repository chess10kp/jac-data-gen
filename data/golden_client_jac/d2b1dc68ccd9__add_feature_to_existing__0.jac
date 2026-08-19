def example() -> bool {
    a = True;
    b = False;

    result = a and b;
    result = a or b;
    result = not a;

    result = a && b;
    result = a || b;

    # New: exclusive-or helper built from the boolean ops
    xor = (a or b) and not (a and b);
    return xor;
}

with entry {
    print(example());
}
