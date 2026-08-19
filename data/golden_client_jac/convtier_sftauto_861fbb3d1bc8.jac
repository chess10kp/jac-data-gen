def check_strings(lst: Any) -> object {
    vowels = ['a', 'e', 'i', 'o', 'u'];
    for word in lst {
        if (word.startswith('t') and word.endswith('d')) {
            length = len(word);
            if is_prime(length) {
                middle_char = word[(length // 2)];
                if (middle_char in vowels) {
                    return True;
                }
            }
        }
    }
    return False;
}



with entry {
    print(check_strings('hello'));
}
