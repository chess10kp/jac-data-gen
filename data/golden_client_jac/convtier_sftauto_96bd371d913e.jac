def check_json_validity(string_to_check: Any) -> object {
    try {
        json.loads(string_to_check);
        return True;
    } except Exception as e {
        return False;
    }
}



with entry {
    print(check_json_validity('hello'));
}
