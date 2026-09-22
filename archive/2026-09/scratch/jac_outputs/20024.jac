"""
Normalize case of some (all-{upper|lower}case) text.
Uses a wordlist to determine which words need capitalization.
"""
def normalize_case(text: str) -> str {
    special_case_words = ['Trento', 'Provincia'];
    text = text.lower();
    for word in special_case_words {
        text.replace(word.lower(), word);
    }
    return text.capitalize();
}