def is_palindrome(string: Any) -> object {
    alphanumeric_string = ''.join(
        char.lower()
        for char in string
        if char.isalnum()
    );
    (left, right) = (0, (len(alphanumeric_string) - 1));
    while (left < right) {
        if (alphanumeric_string[left] != alphanumeric_string[right]) {
            return False;
        }
        left += 1;
        right -= 1;
    }
    return True;
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome('Racecar'));
}
