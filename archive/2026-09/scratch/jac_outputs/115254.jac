"""Check if answer is correct (word overlap meets limit threshold)."""
def is_correct_answer(
    user_answer: str,
    correct_answer: str,
    limit: float,
    answer_handler: Callable[[str], str] | None = None
) -> bool {
    prepared_correct = correct_answer;
    prepared_user = user_answer;
    if answer_handler is not None {
        prepared_correct = answer_handler(correct_answer);
        prepared_user = answer_handler(user_answer);
    }
    correct_words = set(prepared_correct.split());
    user_words = set(prepared_user.split());
    intersection = correct_words.intersection(user_words);
    return len(intersection) / len(user_words) >= limit;
}