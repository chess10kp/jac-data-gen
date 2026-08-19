obj Dog {
    has name: str;
    has age: int;
    has breed: str;
}

with entry {
    dog1 = Dog(name="Buddy", age=3, breed="Labrador");
    dog2 = Dog(name="Max", age=5, breed="Poodle");

    print(f"Dog 1: {dog1.name}, {dog1.age}, {dog1.breed}");
    print(f"Dog 2: {dog2.name}, {dog2.age}, {dog2.breed}");
}
