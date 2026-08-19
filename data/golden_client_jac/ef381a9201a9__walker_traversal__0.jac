# Node
node Person {
    has name: str;
}

# Edge
edge Friend {
    has since: int;
}

# Walker
walker Greeter {
    can start with Root entry {
        visit [-->];
    }

    can greet with Person entry {
        print(f"Hello, {here.name}!");
        visit [-->];
    }
}

with entry {
    # Create nodes
    alice = Person(name="Alice");
    bob = Person(name="Bob");

    # Connect nodes
    root ++> alice;
    alice ++> bob;                        # Untyped
    alice +>:Friend(since=2020):+> bob;  # Typed

    # Query connections
    friends = [alice ->:Friend:->];
    print(f"Alice has {len(friends)} friend(s)");

    # Spawn walker
    root spawn Greeter();
}
