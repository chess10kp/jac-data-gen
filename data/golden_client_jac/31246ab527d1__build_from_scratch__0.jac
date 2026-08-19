obj Person {
    has name: str;
    has age: int;

    def introduce() -> str {
        return f"I'm {self.name}, {self.age} years old.";
    }
}

with entry {
    alice = Person(name="Alice", age=30);
    print(alice.introduce());  # I'm Alice, 30 years old.
}
