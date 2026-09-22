"""Format an ephemeral error when no Quip is found."""
def format_response_not_found_error(command_text: Any) -> object {
    response = {
        "response_type": "ephemeral",
        "text": f"No quip found for `{command_text}`."
    };
    return response;
}