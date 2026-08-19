node Person {
    has name: str;
}

with entry {
    alice = Person(name="Alice");
    bob = Person(name="Bob");
    charlie = Person(name="Charlie");
    dave = Person(name="Dave");

    alice ++> bob;
    alice ++> charlie;
    bob ++> charlie;

    # New: Dave joins the graph and connects to Charlie
    charlie ++> dave;

    root ++> alice;
}
