with entry {
    # Create a dictionary
    person = {
        "name": "Alice",
        "age": 25,
        "city": "Seattle"
    };

    # Access values by key
    print(person["name"]);  # Alice
    print(person["age"]);   # 25

    # Add or modify
    person["job"] = "Engineer";
    person["age"] = 26;

    print(person);
}
