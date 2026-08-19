node Person {
    has name: str;
    has age: int;
}

edge Knows {
    has since: int;
}

walker Greeter {
    can greet with Root entry {
        visit [-->];
    }

    can say_hello with Person entry {
        print(f"Hello, {here.name}!");
        visit [-->];
    }
}

with entry {
    # Build graph
    alice = Person(name="Alice", age=30);
    bob = Person(name="Bob", age=25);

    root ++> alice;
    alice +>: Knows(since=2020) :+> bob;

    # Spawn walker
    root spawn Greeter();
}
