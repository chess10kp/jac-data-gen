"""
    This method looks for active_words in subject in a case-insensitive fashion

    Parameters
    ----------
    subject: string, required
        email subject
    active_words: string, required
        active words represented in a comma delimited fashion

    Returns
    -------
    True
        If any active words were found in subject or,
        No active words are configured
    False
        If no active words were found in subject
    """
def search_active_words(subject: str, active_words: str) -> bool {
    if not active_words {
        return True;
    }
    subject_lower = subject.lower();
    return any(
        word.strip().lower() in subject_lower
        for word in filter(None, active_words.split(','))
    );
}