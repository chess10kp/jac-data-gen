"""Returns s with all non-alphanumeric characters replaced with *."""
def censor_non_alphanum(s: str) -> str {
    def censor(ch: str) -> str {
        if (ch >= 'A' and ch <= 'z') or (ch >= '0' and ch <= '9') {
            return ch;
        }
        return '*';
    }
    return ''.join(censor(ch) for ch in s);
}