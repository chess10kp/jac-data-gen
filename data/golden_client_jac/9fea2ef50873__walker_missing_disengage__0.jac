node Person {
    has name: str;
    has visited: bool = False;
}

walker Greeter {
    can start with Root entry {
        visit [-->];  # Visit nodes connected to root
    }

    can greet with Person entry {
        print(f"Hello, {here.name}!");
        here.visited = True;
    }
}

with entry {
    alice = Person(name="Alice");
    bob = Person(name="Bob");

    root ++> alice;
    alice ++> bob;

    # Spawn walker at root
    root spawn Greeter();
}
