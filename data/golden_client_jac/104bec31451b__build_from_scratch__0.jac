obj Person {
    has name: str;
    has age: int;
    def postinit() -> None {
        print(f"Created {self.name}");
    }
}
