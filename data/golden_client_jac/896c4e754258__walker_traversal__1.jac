node Person {
    has name: str;
}

walker Greeter {
    can start with Root entry {
        print("Walker starting journey!");
        visit [-->];  # Visit all connected nodes
    }

    can greet with Person entry {
        print(f"Hello, {here.name}!");
        visit [-->];  # Visit this person's connections
    }
}

with entry {
    # Build graph
    alice = Person(name="Alice");
    bob = Person(name="Bob");
    charlie = Person(name="Charlie");

    root ++> alice ++> bob ++> charlie;

    # Spawn walker
    root spawn Greeter();
}
