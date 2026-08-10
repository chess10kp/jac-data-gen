"""Convert Mel frequency to frequency.
    Args:
        mel:Mel frequency
    Returns:
        Frequency.
    """
def mel2hz(mel: float) -> float {
    return 700 * (10 ** (mel / 2595.0) - 1);
}