node Greeter {
    has name: str;

    can greet with entry {
        print(f"Hello from {self.name}!");
    }
}
