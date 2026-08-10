"""Count the words of text passed as argument."""
def count_words(text: str) -> int {
    total_words = 0;
    for word in text.split("\n") {
        if word.strip() {
            total_words += 1;
        }
    }
    return total_words;
}