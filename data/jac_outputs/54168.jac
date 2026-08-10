"""
Calculate the probability that two random values selected from an arbitrary
sized pool of unique values will be equal. This is commonly known as the
"Birthday Problem".
"""
def selection_collision(selections: int, poolsize: int) -> float {
    probability = 100.0;
    pool = float(poolsize);
    for i in range(selections) {
        probability = probability * (pool - i) / pool;
    }
    return 100.0 - probability;
}