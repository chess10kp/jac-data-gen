obj Person {
    has name: str;
    has age: int = 0;
    static has count: int = 0;

    # New: postinit that bumps the shared counter
    def postinit {
        Person.count += 1;
    }

    static def total() -> int {
        return Person.count;
    }
}

with entry {
    a = Person(name="Ann");
    b = Person(name="Bo");
    print(Person.total());
}
