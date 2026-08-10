"""Helper function which generates the option block for modals / views"""
def option_from_template(text: str, value: str) -> object {
    return {
        "text": {"type": "plain_text", "text": str(text), "emoji": True},
        "value": str(value)
    };
}