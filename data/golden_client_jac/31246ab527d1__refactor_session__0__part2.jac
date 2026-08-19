obj Person {
    has name: str;
    has age: int;
    has email: str = "";
    def introduce() -> str;
    def have_birthday() -> None;
}

impl Person.introduce() -> str {
    return f"I'm {self.name}, {self.age} years old.";
}

impl Person.have_birthday() -> None {
    self.age += 1;
}

with entry {
    alice = Person(name="Alice", age=30);
    print(alice.introduce());
    alice.have_birthday();
    print(alice.age);
}
