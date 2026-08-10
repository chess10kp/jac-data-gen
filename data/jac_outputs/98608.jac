"""Detects the case of a given word."""
def get_case(word: str, other_tag: str = "O") -> str {
    if word.isupper() {
        return "A";
    } elif word.istitle() {
        return "F";
    } else {
        return other_tag;
    }
}