node Person {
    has name: str;
    has age: int;
}

walker Greeter {
    has greeting: str = "Hello";

    can greet_root with Root entry {
        print(f"{self.greeting} from root!");
        visit [-->];
    }

    can greet_person with Person entry {
        print(f"{self.greeting}, {here.name}!");
        report here.name;
    }
}

with entry {
    root ++> Person(name="Alice", age=25);
    root ++> Person(name="Bob", age=30);
    result = root spawn Greeter();
    print(result.reports);
}
