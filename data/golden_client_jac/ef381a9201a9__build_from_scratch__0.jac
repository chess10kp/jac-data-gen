node Person {
    has name: str;
}

edge Friend {
    has since: int;
}

walker Greeter {
    can greet with Person entry {
        print(f"Hello, {here.name}!");
        visit [-->];
    }
}
