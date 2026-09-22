"""Return the perplexity of a sequence with specified probability and length."""
def perplexity(probability: float, length: int) -> float {
    probability ** -(1 / length)
}