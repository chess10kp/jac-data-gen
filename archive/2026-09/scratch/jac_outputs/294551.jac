""" Case insensitive check of answer.
    Assume inputs are in the correct format, since takeQuiz() accounts
    for
    Args:
        possible (list): List of possible answers for question.
        guess (string): User's guess for question.
    Returns:
        bool: True if guess is in possible, False otherwise.
    """
def checkanswer(possible: list[str], guess: str) -> bool {
    for answer in possible {
        if guess.lower() == answer.lower() {
            return True;
        }
    }
    return False;
}