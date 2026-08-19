node Person {
    has name: str;
    has age: int;
}

walker FindAdults {
    can start with Root entry {
        visit [-->];
    }

    can check with Person entry {
        if here.age >= 18 {
            report here;  # Add to results
        }
        visit [-->];
    }
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
