with entry {
    numbers: list[int] = [1, 2, 3, 4, 5];
    numbers.append(6);

    person: dict[str, any] = {
        "name": "Alice",
        "age": 30
    };

    unique: set[int] = {1, 2, 3};
    point: tuple[int, int] = (10, 20);

    person["email"] = "alice@example.com";
    doubled: list[int] = [n * 2 for n in numbers];
    print(person);
    print(doubled);
}
