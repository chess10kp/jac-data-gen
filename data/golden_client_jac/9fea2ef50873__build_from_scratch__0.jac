node Person {
    has name: str;
    has visited: bool = False;
}

walker Greeter {
    can start with Root entry {
        visit [-->];
    }

    can greet with Person entry {
        print(f"Hello, {here.name}!");
        here.visited = True;
    }
}

with entry {
    alice = Person(name="Alice");
    root ++> alice;
    root spawn Greeter();
}
