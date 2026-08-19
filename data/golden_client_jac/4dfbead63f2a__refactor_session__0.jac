obj Person {
    has name: str;
    has age: int;

    def greet() -> None;
}

impl Person.greet -> None {
    print(f"Hello, my name is {self.name} and I'm {self.age} years old.");
}
