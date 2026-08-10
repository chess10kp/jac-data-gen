"""Calculate union of probabilities p_1 U p_2 U ... U p_n."""
def union(probs: list[float]) -> float {
    while len(probs) > 1 {
        if len(probs) % 2 {
            (p, probs) = (probs[0], probs[1:]);
            probs[0] = probs[0] + p - probs[0] * p;
        }
        probs = [
            probs[i - 1] + probs[i] - probs[i - 1] * probs[i]
            for i in range(1, len(probs), 2)
        ];
    }
    return probs[0];
}