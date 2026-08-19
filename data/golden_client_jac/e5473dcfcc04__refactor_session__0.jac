def build_person() -> dict {
    person = {
        "name": "Alice",
        "age": 25,
        "city": "Seattle"
    };
    print(person["name"]);
    print(person["age"]);
    person["job"] = "Engineer";
    person["age"] = 26;
    return person;
}

with entry {
    print(build_person());
}
