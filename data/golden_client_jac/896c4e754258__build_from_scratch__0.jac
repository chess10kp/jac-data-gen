node Person {
    has name: str;
}

walker Greeter {
    can greet with Person entry {
        print(f"Hello, {here.name}!");
    }
}
