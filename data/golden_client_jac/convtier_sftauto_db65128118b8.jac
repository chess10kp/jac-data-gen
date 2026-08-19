def check_string(string: Any) -> object {
    if (not string.isalpha() or (len(string) < 10)) {
        return False;
    }
    uppercase_count = len(re.findall(r'[A-Z]', string));
    lowercase_count = len(re.findall(r'[a-z]', string));
    digit_count = len(re.findall(r'\d', string));
    if ((uppercase_count < 2) or (lowercase_count < 2) or (digit_count < 2)) {
        return False;
    }
    return True;
}



with entry {
    print(check_string('hello'));
}
