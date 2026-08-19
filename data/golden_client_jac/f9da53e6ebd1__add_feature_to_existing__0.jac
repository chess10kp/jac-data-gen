def example() -> str {
    name = "Alice";
    age = 30;

    greeting = f"Hello, {name}!";
    message = f"In 5 years: {age + 5}";

    # New: nested / conditional interpolation
    status = f"{name} is {'an adult' if age >= 18 else 'a minor'}";

    return f"{greeting} {message} {status}";
}

with entry {
    print(example());
}
