def f(x: int) -> int { return x + 1; }
def g(x: int) -> int { return x * 2; }

def example() {
    a = 1; b = 2; c = 3; cond = True;
    assert (a if cond else b + 1) == a;
    assert (a or b and c) == 1;
    assert (0 < 5 < 10) == True;
    assert (a + b * c) == 7;
    assert (a | b & c) == 3;
    result = a |> f |> g;
    assert result == 4;
    items = [1, 2, 3];
    if (n := len(items)) > 2 { print(n); }
}
