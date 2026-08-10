"""Removes punctuation (:;,.?!) and converts message to upper case."""
def pre_treat_message(message: str) -> str {
    treated_message = message;
    for punct in (':', ';', ',', '.', '?', '!') {
        treated_message = treated_message.replace(punct, '');
    }
    return treated_message.upper();
}