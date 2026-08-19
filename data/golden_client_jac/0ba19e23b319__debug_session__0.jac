obj Person {
    has name: str;
}

with entry {
    p = Person(name="Alice");
    p.height = 175; # INVALID: 'height' is not in 'has'
    print(p.height);
}
