obj Person {
    has name: str,
        height: int = 0;
}

with entry {
    p = Person(name="Alice");
    p.height = 175;
    print(p.height);
}
