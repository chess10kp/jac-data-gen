"""
Returns True, if the state is already visited

state: a list representing the state to be checked
check_dict: a dict storing the visited states
check: a boolean value, if True, marks the given state as visited if it was not so
"""
def been_there(state: list[int], check_dict: dict[str, bool], check: bool) -> bool {
    key = str(state);
    if key in check_dict {
        return True;
    }
    if check {
        check_dict[key] = True;
    }
    return False;
}