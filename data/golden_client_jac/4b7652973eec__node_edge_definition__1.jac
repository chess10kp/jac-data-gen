obj Dog { has name: str, age: int; }
obj Cat { has name: str, age: int; }

with entry {
    pets: list = [
        Dog(name="Rex", age=5),
        Cat(name="Whiskers", age=3),
        Dog(name="Buddy", age=2)
    ];

    # Filter by type -- keep only Dogs
    dogs = pets[?:Dog];
    print(dogs);  # [Dog(name='Rex', age=5), Dog(name='Buddy', age=2)]

    # Filter by field condition
    young = pets[?age < 4];
    print(young);  # [Cat(name='Whiskers', age=3), Dog(name='Buddy', age=2)]

    # Combined type + field filter
    young_dogs = pets[?:Dog, age < 4];
    print(young_dogs);  # [Dog(name='Buddy', age=2)]
}
