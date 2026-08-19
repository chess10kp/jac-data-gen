node Person {
    has name: str;
    has age: int;
}

walker FindFirst {
    can start with Root entry {
        visit [-->];
    }

    can check with Person entry {
        if here.age >= 18 {
            report here;
            disengage;
        }
        visit [-->];
    }
}

with entry {
    root ++> Person(name="Alice", age=15);
    root ++> Person(name="Bob", age=25);
    result = root spawn FindFirst();
    print(result.reports[0].name);
}
