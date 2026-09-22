"""Remove all characters which might break a commit message."""
def sanitize_message(message: str) -> str {
    if not message {
        message = 'empty AccuRev promote message';
    } else {
        message = message.strip('"').lstrip('\n');
        message = ''.join(i for i in message if ord(i) < 128);
    }
    return message;
}