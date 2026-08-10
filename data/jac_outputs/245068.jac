"""Returns the element of VALID_WORDS that has the smallest difference
from USER_WORD. Instead returns USER_WORD if that difference is greater
than LIMIT."""
def autocorrect(
    user_word: str,
    valid_words: list[str],
    diff_function: Callable[[str, str, int | float], int | float],
    limit: int | float
) -> str {
    "*** YOUR CODE HERE ***";
    if user_word in valid_words {
        return user_word;
    }
    tmp_word = user_word;
    tmp_diff = limit;
    for w in valid_words {
        curr_diff = diff_function(user_word, w, limit);
        if curr_diff < tmp_diff or curr_diff == tmp_diff == limit {
            tmp_word = w;
            tmp_diff = curr_diff;
        }
    }
    return tmp_word;
}