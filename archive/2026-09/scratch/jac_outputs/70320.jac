"""Return True if adding both number strings would result in an int."""
def problem_2(number_str_1: str, number_str_2: str) -> bool {
    one_is_int = "." not in number_str_1;
    two_is_int = "." not in number_str_2;
    return one_is_int and two_is_int;
}