"""A function to determine whether the instruction contain any calls to any functions."""
def has_function_call(instructions: list[list[int | str]]) -> bool {
    for line in instructions {
        for each in line {
            if `type(each) == str {
                return True;
            }
        }
    }
    return False;
}