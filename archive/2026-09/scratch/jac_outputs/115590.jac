"""Return message about sharing.
    Time and space complexity are both O(1).
    """
def two_fer(name: str | None) -> str {
    if name is None {
        name = "you";
    }
    return f"One for {name}, one for me.";
}