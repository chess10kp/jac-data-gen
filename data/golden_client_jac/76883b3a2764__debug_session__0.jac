obj Dog {
    has name: str;
    has age: int;

    def bark {
        print(f"{self.name} says Woof!");
    }

    def birthday {
        self.age += 1;
        print(f"Happy birthday! {self.name} is now {self.age}");
    }
}

with entry {
    my_dog = Dog(name="Buddy", age=3);
    my_dog.bark();
    my_dog.birthday();
}
