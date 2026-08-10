"""Kendall distance with penalty p between two partial rank lists (lists with ties)."""
def partial_kendall(s1: list[float], s2: list[float], p: float = 0.5) -> float {
    card_d = 0;
    card_r1 = 0;
    card_r2 = 0;
    k = len(s1);
    for i in range(len(s1)) {
        for j in range(len(s2)) {
            if s1[i] < s1[j] and s2[i] > s2[j] {
                card_d += 1;
            } elif s1[i] == s1[j] and s2[i] != s2[j] {
                card_r1 += 1;
            } elif s2[i] == s2[j] and s1[i] != s1[j] {
                card_r2 += 1;
            }
        }
    }
    return (2 / (k * (k - 1))) * (card_d + p * (card_r1 + card_r2));
}