"""Lets the computer always choose the opposite of the user."""
def frustrator_function(choice_subject: str, choice_computer: str) -> str {
    if choice_subject == 'h' {
        return 't';
    }
    return 'h';
}