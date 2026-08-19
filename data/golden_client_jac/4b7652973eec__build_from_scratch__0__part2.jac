obj Dog { has name: str, age: int; }
obj Cat { has name: str, age: int; }

with entry {
    pets: list = [
        Dog(name="Rex", age=5),
        Cat(name="Whiskers", age=3),
        Dog(name="Buddy", age=2)
    ];

    dogs = pets[?:Dog];
    print(dogs);

    # Filter by a field condition
    young = pets[?age < 4];
    print(young);
}
