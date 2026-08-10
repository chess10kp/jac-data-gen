"""Obtain player guess

    Params:
        f_guess: int
        f_turns_left: int

    Returns:
        int, str
    """
def guess_number(f_guess: Any, f_turns_left: Any) -> object {
    try {
        if ((f_guess < 1) or (f_guess > 9)) {
            raise ValueError;
        }
        return (f_guess, (f_turns_left - 1));
    } except ValueError {
        return ('\nRULES: Please enter a number between 1 and 9.', (f_turns_left - 1));
    } except TypeError {
        return ('\nRULES: Please enter a number between 1 and 9.', (f_turns_left - 1));
    }
}