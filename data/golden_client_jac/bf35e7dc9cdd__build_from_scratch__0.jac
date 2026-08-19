node Person {
    has name: str;
    has age: int;

    def greet() -> str {
        return f"Hi, I'm {self.name}!";
    }
}

with entry {
    alice = Person(name="Alice", age=30);
    print(alice.greet());
}
