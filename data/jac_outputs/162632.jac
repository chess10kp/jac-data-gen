"""Next power of two for a given input, with a minimum of 16 and a maximum of 512."""
def next_pow_two(max_sent_tokens: int) -> int {
    pow_two = [16, 32, 64, 128, 256, 512];
    if max_sent_tokens <= pow_two[0] {
        return pow_two[0];
    }
    if max_sent_tokens >= pow_two[-1] {
        return pow_two[-1];
    }
    idx = [max_sent_tokens > j for j in pow_two].index(False);
    return pow_two[idx];
}