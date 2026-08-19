def validate_string(string: Any) -> object {
    if ((len(string) < 6) or (len(string) > 20)) {
        return False;
    }
    if not re.search(r"[A-Z]", string) {
        return False;
    }
    if not re.search(r"[a-z]", string) {
        return False;
    }
    if not re.search(r"\d", string) {
        return False;
    }
    return True;
}



with entry {
    print(validate_string('hello'));
}
