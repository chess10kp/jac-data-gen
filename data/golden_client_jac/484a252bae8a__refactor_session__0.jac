obj Profile {
    has name: str = "Alice";
    has age: int = 25;
    has height: float = 5.6;
    has is_student: bool = True;
    has numbers: list = [1, 2, 3];
    has coords: tuple = (10, 20);
    has person: dict = {"name": "Alice", "age": 25};
    has unique: set = {1, 2, 3};

    def show() -> None {
        print(f"Name: {self.name}, Age: {self.age}");
        print(f"Numbers: {self.numbers}");
    }
}
with entry {
    p = Profile();
    p.show();
}
