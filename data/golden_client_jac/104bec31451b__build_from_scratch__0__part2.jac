obj Person {
    has name: str;
    has age: int;

    def postinit() -> None {
        # Called after the auto-generated init completes
        print(f"Created {self.name}");
    }

    def greet() -> str {
        return f"Hi, I'm {self.name}";
    }
}

with entry {
    # Usage
    person = Person(name="Alice", age=30);
    print(person.greet());
}
