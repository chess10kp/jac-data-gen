def check_parentheses(input_string: str) -> bool {
    stack = [];
    for char in input_string {
        if (char == '(') {
            stack.append(char);
        } elif (char == ')') {
            if not stack {
                return False;
            }
            stack.pop();
        }
    }
    return (len(stack) == 0);
}



with entry {
    print(check_parentheses('hello'));
}
