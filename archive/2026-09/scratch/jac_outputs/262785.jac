"""Determine the target for the current CopyPhrase sequence."""
def copy_phrase_target(phrase: str, current_text: str, backspace: str = '<') -> str {
    try {
        phrase.index(current_text);
        return phrase[len(current_text)];
    } except ValueError {
        return backspace;
    }
}