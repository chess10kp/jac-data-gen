def validate_json(json_obj: Any) -> object {
    required_fields = [
        "name",
        "age",
        "email",
        "address",
        "hobbies",
        "education",
        "friends",
        "projects"
    ];
    for field in required_fields {
        if (field not in json_obj) {
            return False;
        }
    }
    return True;
}



with entry {
    print(validate_json('hello'));
}
