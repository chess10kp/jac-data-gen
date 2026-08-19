def contains_uv_consecutively(string: Any) -> object {
    string = string.lower();
    for i in range((len(string) - 1)) {
        if ((string[i] == 'u') and (string[(i + 1)] == 'v')) {
            return True;
        }
    }
    return False;
}



with entry {
    print(contains_uv_consecutively('hello'));
}
