obj Person {
    has name: str,
        height: int = 0; # Declare all expected fields
}

with entry {
    p = Person(name="Alice", height=175);
    print(p.height);
}
