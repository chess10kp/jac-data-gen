"""A basic object archetype with fields and methods."""

obj Person {
    has name: str,
        age: int,
        email: str = "";

    def greet() -> str {
        return f"Hi, I'm {self.name}, age {self.age}";
    }

    def is_adult() -> bool {
        return self.age >= 18;
    }
}

with entry {
    p = Person(name="Alice", age=30, email="alice@example.com");
    print(p.greet());
    print(f"Adult: {p.is_adult()}");
}
