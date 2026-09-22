"""Checks a response and determines if it is correct.

    :param correct: The correct answer.
    :param allowed: List of possible answers.
    :param response: The answer provided by the player.
    :return: "correct", "incorrect", or "exit"
    """
def process_response(correct: str, allowed: list[str], response: str) -> str {
    try {
        response = response.casefold();
    } except AttributeError {
        ;
    }
    if response not in allowed {
        return "exit";
    } elif response == correct {
        print("Congratulations! Your are correct.\n");
        return "correct";
    } else {
        print("Incorrect\n");
        return "incorrect";
    }
}