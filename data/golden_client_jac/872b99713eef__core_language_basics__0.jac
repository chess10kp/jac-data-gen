def f(x: int) -> int { return x + 1; }
def g(x: int) -> int { return x * 2; }

def example() {
    a = 1; b = 2; c = 3; cond = True;

    # Ternary binds loosely
    x = a if cond else b + 1;   # x = a if cond else (b + 1)

    # Logical operators
    x = a or b and c;           # x = a or (b and c)
    x = not a and b;            # x = (not a) and b

    # Comparison chaining
    x = 5;
    valid = 0 < x < 10;         # (0 < x) and (x < 10)

    # Arithmetic
    x = a + b * c;              # x = a + (b * c)
    x = a ** b ** c;            # x = a ** (b ** c)

    # Bitwise
    x = a | b & c;              # x = a | (b & c)
    x = a << 2 + 1;             # x = a << (2 + 1)

    # Pipe operators
    result = a |> f |> g;       # result = g(f(a))

    # Walrus in condition
    items = [1, 2, 3];
    if (n := len(items)) > 2 { print(n); }
}
