"""Test if this is a nickname setting message."""
def is_set_nickname(string: str, nickname: str) -> bool {
    return string.startswith((
        f"{nickname} set the nickname for ",
        f"{nickname} set his own nickname to",
        f"{nickname} set her own nickname to",
        f"{nickname} set your nickname to"
    ));
}