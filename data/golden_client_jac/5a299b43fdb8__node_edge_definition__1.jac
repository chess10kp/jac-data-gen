node Person {
    has name: str;

    # Node's perspective: "When a Visitor visits me"
    can greet with Visitor entry {
        print(f"{self.name} says: Welcome, visitor!");
    }
}

walker Visitor {
    can start with Root entry {
        visit [-->];
    }

    # Walker's perspective: "When I visit a Person"
    can meet with Person entry {
        print(f"Visitor says: Hello, {here.name}!");
        visit [-->];
    }
}

with entry {
    alice = Person(name="Alice");
    root ++> alice;

    root spawn Visitor();
}
