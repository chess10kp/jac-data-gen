"""Capitalizes words in a string, avoiding possessives being capitalized."""
def capitalize_correct(phrase: str) -> str {
    phrase = phrase.strip();
    return " ".join(w.capitalize() for w in phrase.split());
}