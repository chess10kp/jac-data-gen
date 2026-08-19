def make_squares() -> list {
    return [x ** 2 for x in range(10)];
}
def make_square_dict() -> dict {
    return {x: x**2 for x in range(5)};
}
def format_message(name: str, age: int) -> str {
    return f"Hello, {name}! You are {age} years old.";
}
def classify(age: int) -> str {
    return "adult" if age >= 18 else "minor";
}
with entry {
    print(f"Squares: {make_squares()}");
    print(f"Square dict: {make_square_dict()}");
    name = "Alice";
    age = 25;
    print(format_message(name, age));
    print(f"Status: {classify(age)}");
    (x, y) = (10, 20);
    print(f"x={x}, y={y}");
    (x, y) = (y, x);
    print(f"After swap: x={x}, y={y}");
}
