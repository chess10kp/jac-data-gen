"""Calculates overall rating from rating array."""
def calculate_rating(rating: list[int]) -> float {
    cumulative = 0;
    weight = 0;
    for i in range(1, 6) {
        cumulative += rating[i] * i;
        weight += rating[i];
    }
    if weight > 0 and cumulative > 0 {
        return cumulative / weight;
    }
    return 0;
}