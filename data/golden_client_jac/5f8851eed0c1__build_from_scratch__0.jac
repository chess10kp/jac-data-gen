node Person {
    has name: str;
    has age: int;
}

edge Knows {
    has since: int;
}

walker Greeter {
    can say_hello with Person entry {
        print(f"Hello, {here.name}!");
        visit [-->];
    }
}
