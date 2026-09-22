"""Return substring from a text based on start and end substrings delimited by ::."""
def get_fragment(text: Any, startend: Any) -> object {
    startend = startend.split("::");
    if ((startend[0] not in text) or (startend[1] not in text)) {
        return;
    }
    start_idx = text.index(startend[0]);
    end_idx = text.index(startend[1]);
    if (end_idx < start_idx) {
        return;
    }
    return text[start_idx:(end_idx + len(startend[1]))];
}