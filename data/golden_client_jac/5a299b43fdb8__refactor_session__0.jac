node Person {
    has name: str;
    can greet with Visitor entry;
}

walker Visitor {
    can start with Root entry;
    can meet with Person entry;
}

impl Visitor.start {
    visit [-->];
}

impl Visitor.meet {
    print(f"Visitor says: Hello, {here.name}!");
    visit [-->];
}

with entry {
    alice = Person(name="Alice");
    root ++> alice;
    root spawn Visitor();
}
