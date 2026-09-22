""" Calculate the desired key size in 64 byte blocks.
    """
def key_size(message: Any) -> object {
    return ((len(message) // 64) + 1);
}