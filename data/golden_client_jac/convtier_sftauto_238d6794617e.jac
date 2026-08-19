def check_strings(lst: Any) -> object {
    for string in lst {
        if (string.startswith("t") and (len(string) > 3)) {
            return True;
        }
    }
    return False;
}



with entry {
    print(check_strings('hello'));
}
