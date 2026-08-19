node Person {
    has name: str;
}

with entry {
    alice = Person(name="Alice");
    bob = Person(name="Bob");
    charlie = Person(name="Charlie");

    # Connect them! (Create edges)
    alice ++> bob;      # Alice → Bob
    alice ++> charlie;  # Alice → Charlie
    bob ++> charlie;    # Bob → Charlie

    # That's it! You've built a graph!

    # root is a special global node
    # that is always available (more on root later)
    root ++> alice;
}
