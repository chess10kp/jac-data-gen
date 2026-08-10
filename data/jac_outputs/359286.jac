"""Return the concordance of words around a keyword position using a window."""
def get_concordance_string(text: str, keyword: str, idx: int, window: int) -> str {
    text_list = text.split();
    text_size = len(text_list);
    start_idx = idx - window if idx >= window else 0;
    end_idx = text_size if (idx + window) >= text_size else idx + window + 1;
    return ' '.join(text_list[start_idx:end_idx]);
}