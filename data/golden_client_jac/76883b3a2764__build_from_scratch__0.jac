obj Dog {
    has name: str;
    has age: int;

    def bark {
        print(f"{self.name} says Woof!");
    }
}

with entry {
    my_dog = Dog(name="Buddy", age=3);
    my_dog.bark();
}
