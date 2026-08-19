obj Person {
    has name: str;
    has age: int;
    has email: str = "";  # default value

    def introduce() -> str {
        return f"I'm {self.name}, {self.age} years old.";
    }

    def have_birthday() -> None {
        self.age += 1;
    }
}

with entry {
    alice = Person(name="Alice", age=30);
    print(alice.introduce());  # I'm Alice, 30 years old.

    alice.have_birthday();
    print(alice.age);  # 31
}
