def is_palindrome(s: Any) -> object {
    (i, j) = (0, (len(s) - 1));
    while (i < j) {
        while ((i < j) and not s[i].isalnum()) {
            i += 1;
        }
        while ((i < j) and not s[j].isalnum()) {
            j -= 1;
        }
        if (s[i].lower() != s[j].lower()) {
            return False;
        }
        i += 1;
        j -= 1;
    }
    return True;
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome('Racecar'));
}
