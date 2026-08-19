obj PersonRecord {
    has name: str;
    has age: int;
}

with entry {
    numbers: list[int] = [1, 2, 3, 4, 5];
    numbers.append(6);

    person = PersonRecord(name="Alice", age=30);

    unique: set[int] = {1, 2, 3};
    point: tuple[int, int] = (10, 20);

    print(numbers, person.name, person.age, unique, point);
}
