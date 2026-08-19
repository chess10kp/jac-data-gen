def contains_five_consecutive_special_chars(string: Any) -> object {
    count = 0;
    for char in string {
        if not char.isalnum() {
            count += 1;
            if (count >= 5) {
                return True;
            }
        } else {
            count = 0;
        }
    }
    return False;
}



with entry {
    print(contains_five_consecutive_special_chars('hello'));
}
