node Greeter {
    has name: str;
    has greeting: str = "Hello";

    can greet with entry {
        print(f"{self.greeting} from {self.name}!");
    }

    can farewell with exit {
        print(f"Goodbye from {self.name}!");
    }
}

with entry {
    g = root ++> Greeter(name="Alice");
}
