def is_palindrome(string: Any) -> object {
    string = string.lower();
    string = ''.join(
        char
        for char in string
        if char.isalnum()
    );
    if (string == string[::-1]) {
        return "Palindrome";
    } else {
        return "Not a palindrome";
    }
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome('Racecar'));
}
