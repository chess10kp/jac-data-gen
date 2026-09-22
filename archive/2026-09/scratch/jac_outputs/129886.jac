"""Checks if text is a command. Telegram chat commands start with the '/' character."""
def is_command(text: str | None) -> bool {
    if text is None {
        return False;
    }
    return text.startswith('/');
}