"""Removes question mark strings, turning them to nulls.

    Parameters
    ----------
    content: :class:`str`
        A string to clean.

    Returns
    -------
    :class:`str`
        The string, or None if it was a question mark.
    """
def clean_question_mark(content: Any) -> object {
    if not content {
        return None;
    }
    if ("?" in content) {
        return None;
    }
    return content.strip();
}