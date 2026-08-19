obj Person {
    has name: str;
    has age: int;

    def greet() -> str {
        return f"Hi, I'm {self.name}";
    }

    # New: celebrate a birthday and return the new age
    def have_birthday() -> int {
        self.age += 1;
        return self.age;
    }
}

with entry {
    p = Person(name="Ada", age=30);
    print(p.greet());
    print(f"Now {p.have_birthday()}");
}
