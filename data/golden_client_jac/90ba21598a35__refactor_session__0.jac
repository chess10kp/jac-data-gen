def _norm_tag(word: str) -> str;

impl norm_tag {
    return word.lower().rstrip(".,!?;:");
}
