node Person {
    has name: str;
}

walker Greeter {
    can start with Root entry;
    can greet with Person entry;
}

impl Greeter.start {
    print("Walker starting journey!");
    visit [-->];
}

impl Greeter.greet {
    print(f"Hello, {here.name}!");
    visit [-->];
}

with entry {
    alice = Person(name="Alice");
    bob = Person(name="Bob");
    charlie = Person(name="Charlie");
    root ++> alice ++> bob ++> charlie;
    root spawn Greeter();
}
