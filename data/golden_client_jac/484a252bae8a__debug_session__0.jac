with entry {
    # Primitives
    name: str = "Alice";
    age: int = 25;
    height: float = 5.6;
    is_student: bool = True;

    # Collections
    numbers: list = [1, 2, 3];
    coords: tuple = (10, 20);
    person: dict = {"name": "Alice", "age": 25};
    unique: set = {1, 2, 3};

    print(f"Name: {name}, Age: {age}");
    print(f"Numbers: {numbers}");
}
