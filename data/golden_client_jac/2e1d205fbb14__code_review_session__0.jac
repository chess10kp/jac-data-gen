node Person {
    has name: str;
    has age: int;
}

with entry {
    # Create and assign
    alice = Person(name="Alice", age=30);
    bob = Person(name="Bob", age=25);

    # Attach them to the graph so they are reachable and persist
    root ++> alice;
    root ++> bob;

    # Inline creation in connection
    root ++> Person(name="Charlie", age=35);
}
