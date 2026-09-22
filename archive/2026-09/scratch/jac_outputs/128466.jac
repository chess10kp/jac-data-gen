"""Method to extract message id from telegram request."""
def get_message(data: dict[str, dict[str, str]]) -> str {
    return data['message']['text'];
}