def validate_string(s: Any) -> object {
    lowercase = False;
    for c in s {
        if (not c.islower() and not c.isalpha()) {
            return False;
        }
        if c.islower() {
            lowercase = True;
        }
    }
    return lowercase;
}



with entry {
    print(validate_string('hello'));
    print(validate_string('Hello, World!'));
}
