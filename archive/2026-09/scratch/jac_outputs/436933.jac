"""Vectorized string search"""
def word_counter(words: list[str], text: list[str]) -> list[int] {
    total = [0] * len(text);
    for (i, txt) in enumerate(text) {
        for word in words {
            if word in txt {
                total[i] = total[i] + 1;
            }
        }
    }
    return total;
}