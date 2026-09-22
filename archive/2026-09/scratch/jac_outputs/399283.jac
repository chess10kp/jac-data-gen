""" stretches the samples to cover a range of width 2**bits,
    so we can convert to ints later.
    """
def stretch(audio: list[float], byte_width: int) -> list[float] {
    audio * ((2 ** ((8 * byte_width) - 1)) - 1)
}