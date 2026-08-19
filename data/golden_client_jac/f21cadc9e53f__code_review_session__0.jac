def double(x: int) -> int { return x * 2; }
def add_one(x: int) -> int { return x + 1; }

def example() -> int {
    data = 5;
    result = data |> double |> add_one;
    return result;
}
