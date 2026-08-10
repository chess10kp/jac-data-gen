"""
    Return True if input is palindrome, False otherwise.

    Args:
       input(str): input to be checked if it is palindrome
    """
def is_palindrome(input: Any) -> object {
    if (len(input) <= 1) {
        return True;
    } else {
        first_char = input[0];
        last_char = input[-1];
        sub_input = input[1:-1];
        return ((first_char == last_char) and is_palindrome(sub_input));
    }
}