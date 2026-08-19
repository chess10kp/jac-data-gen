def validate_value(value: Any) -> object {
    if (isinstance(value, int) and (value > 100)) {
        return True;
    }
    return False;
}



with entry {
    print(validate_value('hello'));
}
