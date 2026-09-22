"""
Extract an identifier for message editing. Returned value is guaranteed
to be a tuple.
"""
def message_identifier(msg: dict[str, str | dict[str, int]]) -> tuple[int, int] | tuple[str] {
    if 'chat' in msg and 'message_id' in msg {
        return (msg['chat']['id'], msg['message_id']);
    }
    if 'inline_message_id' in msg {
        return (msg['inline_message_id'], );
    }
    raise ValueError();
}