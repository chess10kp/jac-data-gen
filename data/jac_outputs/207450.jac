"""Check the brackets in the expression."""
def valid_num_brackets(expression: list[str]) -> bool {
    brackets = 0;
    for item in expression {
        if item == '(' {
            brackets += 1;
        } elif item == ')' {
            brackets -= 1;
            if brackets < 0 {
                return False;
            }
        }
    }
    return brackets == 0;
}