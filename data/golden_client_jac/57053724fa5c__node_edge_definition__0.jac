node Person {
    has name: str;
    has age: int;
}

with entry {
    # Create node instances
    alice = Person(name="Alice", age=25);
    bob = Person(name="Bob", age=30);
    charlie = Person(name="Charlie", age=28);

    print(f"{alice.name} is {alice.age} years old");
}
