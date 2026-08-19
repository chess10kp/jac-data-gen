node Person {
    has name: str;
}

with entry {
    alice = Person(name="Alice");
    bob = Person(name="Bob");

    root ++> alice;
    alice ++> bob;

    people = [root -->];
    print(len(people));
}
