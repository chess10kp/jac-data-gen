def double(x: int) -> int {
    return x * 2;
}

with entry {
    name: str = "alice";
    age: int = 30;
    tags: list[str] = ["a", "b"];
    doubled: list[int] = [n * 2 for n in [1, 2, 3]];
    label: str = "adult" if age >= 18 else "minor";
    square = lambda(x: int) -> int { return x * x; };
    print(square(5));
}
