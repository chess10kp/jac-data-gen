"""Returns message id with < and > prepended and appended respectively.

Required format for exchangelib filter."""
def check_message_id_format(message_id: str) -> str {
    message_id = message_id.strip();
    if not message_id.startswith("<") {
        message_id = f"<{message_id}";
    }
    if not message_id.endswith(">") {
        message_id = f"{message_id}>";
    }
    return message_id;
}