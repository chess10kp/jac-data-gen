node Person {
    has name: str;
    has age: int;
}

walker FindAdults {
    can check with Root entry {
        for person in [-->][?:Person] {
            if person.age >= 18 {
                report person;
            }
        }
    }
}

test "find adults" {
    root ++> Person(name="Alice", age=30);
    root ++> Person(name="Bob", age=15);
    root ++> Person(name="Carol", age=25);

    result = root spawn FindAdults();

    assert len(result.reports) == 2;
    names = [p.name for p in result.reports];
    assert "Alice" in names;
    assert "Carol" in names;
    assert "Bob" not in names;
}
