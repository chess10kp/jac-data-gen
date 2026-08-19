node Person {
    has name: str;
    has visited: bool = False;
}

walker Greeter {
    can start with Root entry;
    can greet with Person entry;
}

impl Greeter.start {
    visit [-->];
}

impl Greeter.greet {
    print(f"Hello, {here.name}!");
    here.visited = True;
}

with entry {
    alice = Person(name="Alice");
    bob = Person(name="Bob");

    root ++> alice;
    alice ++> bob;

    root spawn Greeter();
}
