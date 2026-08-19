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
            disengage;  # Stop immediately -- don't visit more nodes
        }
        visit [-->];
    }
}

with entry {
    root ++> Person(name="Alice", age=15);
    root ++> Person(name="Bob", age=25);
    root ++> Person(name="Carol", age=30);

    result = root spawn FindFirst();
    print(f"First adult: {result.reports[0].name}");
}
