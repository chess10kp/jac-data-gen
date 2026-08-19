node Person {
    has name: str;
    has age: int;
}

walker FindAdults {
    has min_age: int = 18;

    can start with Root entry;
    can check with Person entry;
}

impl FindAdults.start {
    visit [-->];
}

impl FindAdults.check {
    if here.age >= self.min_age {
        report here;
    }
    visit [-->];
}

with entry {
    root ++> Person(name="Alice", age=30);
    root ++> Person(name="Bob", age=15);
    root ++> Person(name="Carol", age=25);

    result = root spawn FindAdults();

    print(f"Found {len(result.reports)} adults");
    for person in result.reports {
        print(f"  - {person.name}");
    }
}
