def is_palindrome(string: Any) -> object {
    string = string.lower();
    stack = [];
    for char in string {
        stack.append(char);
    }
    reversed_string = "";
    while (len(stack) > 0) {
        reversed_string += stack.pop();
    }
    return (string == reversed_string);
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome('Racecar'));
}
