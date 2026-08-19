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
            report here;
        }
        visit [-->];
    }
}

with entry {
    root ++> Person(name="Alice", age=30);
    root ++> Person(name="Bob", age=15);
    result = root spawn FindAdults();
    print(len(result.reports));
}
