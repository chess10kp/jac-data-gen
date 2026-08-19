def _norm_tag(word: str) -> str {
    return word.strip(".,!?;:").lower();
}
