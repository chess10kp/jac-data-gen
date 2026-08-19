node Person {
    has name: str;
    has age: int;

    def greet() -> str {
        return f"Hi, I'm {self.name}!";
    }
}

with entry {
    # Create nodes (just like regular objects)
    alice = Person(name="Alice", age=30);
    bob = Person(name="Bob", age=25);

    # Use them like regular objects
    print(alice.greet());  # Hi, I'm Alice!
    print(bob.age);        # 25
}
