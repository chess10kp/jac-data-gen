node Person {
    has name: str;
    has age: int;
}

with entry {
    alice = Person(name="Alice", age=25);
    print(alice.name);
}
