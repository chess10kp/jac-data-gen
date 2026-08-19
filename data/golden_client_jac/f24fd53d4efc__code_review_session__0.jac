obj Person {
    has name: str,
        height_cm: int = 0; # Name the unit so callers can't misread it
}

with entry {
    p = Person(name="Alice", height_cm=175);
    print(p.height_cm);
}
