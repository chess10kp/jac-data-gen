node Person {
    has name: str;
    has age: int;
}

with entry {
    # Create and assign
    alice = Person(name="Alice", age=30);
    bob = Person(name="Bob", age=25);

    # Inline creation in connection
    root ++> Person(name="Charlie", age=35);
}
