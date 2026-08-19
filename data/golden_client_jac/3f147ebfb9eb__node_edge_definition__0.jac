node Person {
    has name: str;
    has age: int;
}

walker AgeCollector {
    can start with Root entry {
        visit [-->];
    }

    can collect with Person entry {
        report here.age;  # Send age back
        visit [-->];      # Continue walking
    }
}

with entry {
    alice = Person(name="Alice", age=25);
    bob = Person(name="Bob", age=30);
    charlie = Person(name="Charlie", age=28);

    root ++> alice ++> bob ++> charlie;

    ages = root spawn AgeCollector();
    print(f"Collected ages: {ages.reports}");  # [25, 30, 28]
}
