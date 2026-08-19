obj Dog { has name: str, age: int; }
obj Cat { has name: str, age: int; }

def only_dogs(pets: list) -> list {
    return pets[?:Dog];
}

def younger_than(pets: list) -> list {
    return pets[?age < 4];
}

with entry {
    pets: list = [
        Dog(name="Rex", age=5),
        Cat(name="Whiskers", age=3),
        Dog(name="Buddy", age=2)
    ];
    print(only_dogs(pets));
    print(younger_than(pets));
    print(pets[?:Dog, age < 4]);
}
