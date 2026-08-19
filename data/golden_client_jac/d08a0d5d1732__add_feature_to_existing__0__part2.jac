obj Person {
    has name: str;
    has age: int;
    has email: str = "";

    def greet() -> str {
        return f"Hi, I'm {self.name}";
    }

    def contact() -> str {
        return self.email if self.email else "no email";
    }
}

with entry {
    p = Person(name="Alice", age=30, email="alice@example.com");
    print(p.greet());
    print(p.contact());
}
