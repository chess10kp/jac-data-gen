"""dice coefficient 2nt / (na + nb)."""
def dice_coefficient(a: str, b: str) -> float {
    if not len(a) or not len(b) {
        return 0.0;
    }
    if len(a) == 1 {
        a = a + '.';
    }
    if len(b) == 1 {
        b = b + '.';
    }
    a_bigram_list = [a[i:i + 2] for i in range(len(a) - 1)];
    b_bigram_list = [b[i:i + 2] for i in range(len(b) - 1)];
    a_bigrams = set(a_bigram_list);
    b_bigrams = set(b_bigram_list);
    overlap = len(a_bigrams & b_bigrams);
    return overlap * 2.0 / (len(a_bigrams) + len(b_bigrams));
}