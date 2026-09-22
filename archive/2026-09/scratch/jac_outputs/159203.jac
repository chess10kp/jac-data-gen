"""Count the characters of a password for compliance with the puzzle."""
def new_compliance(pos_a: int, pos_b: int, char: str, password: str) -> int {
    test_result = 0;
    if password[pos_a - 1] is char or password[pos_b - 1] is char {
        if password[pos_a - 1] is not password[pos_b - 1] {
            test_result = 1;
        }
    }
    return test_result;
}