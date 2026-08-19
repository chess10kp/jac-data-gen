obj Person {
    has name: str;
    has age: int;

    def greet() -> str {
        return f"Hi, I'm {self.name}";
    }
}
