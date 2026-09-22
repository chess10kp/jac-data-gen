"""Format pydantic's error message field."""
def format_pydantic_error_message(msg: str) -> str {
    msg = msg.replace("str type expected", "string type expected");
    return msg;
}