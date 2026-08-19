obj Person {
    has name: str;
    has age: int;

    def postinit() -> None {
        if self.age < 0 {
            raise ValueError(f"Invalid age: {self.age}");
        }
        print(f"Created {self.name}");
    }

    def greet() -> str {
        return f"Hi, I'm {self.name}";
    }
}

with entry {
    person = Person(name="Alice", age=30);
    print(person.greet());
}
