def reverse_string(string: Any) -> object {
    stack = [];
    for char in string {
        stack.append(char);
    }
    reversed_string = "";
    while stack {
        reversed_string += stack.pop();
    }
    return reversed_string;
}



with entry {
    print(reverse_string('hello'));
    print(reverse_string('Racecar'));
    print(reverse_string('abcabc'));
}
