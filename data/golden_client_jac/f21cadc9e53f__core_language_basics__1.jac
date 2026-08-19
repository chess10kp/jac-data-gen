def double(x: int) -> int { return x * 2; }
def add_one(x: int) -> int { return x + 1; }

def example() {
    data = 5;

    # Forward pipe - data flows left to right
    result = data |> double |> add_one;

    # Equivalent to:
    result = add_one(double(data));
}
