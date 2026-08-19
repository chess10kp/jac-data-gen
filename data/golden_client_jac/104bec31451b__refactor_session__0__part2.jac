obj Person {
    has name: str;
    has age: int;
    def postinit() -> None;
    def greet() -> str;
}
impl Person.postinit {
    print(f"Created {self.name}");
}
impl Person.greet {
    return f"Hi, I'm {self.name}";
}
with entry {
    person = Person(name="Alice", age=30);
    print(person.greet());
}
