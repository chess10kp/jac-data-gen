"""Helper function to assist in handling multiple translations of a message."""
def _translate(messages: dict[str, str], language_code: str) -> str {
    try {
        the_message = messages[language_code];
    } except KeyError {
        the_message = messages["en"];
    }
    return the_message;
}