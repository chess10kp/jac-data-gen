"""Wrap a message string into the minimum acceptable Alexa response JSON."""
def response_from_message(message: str) -> dict {
    return {
        'version': '1.0',
        'response': {'outputSpeech': {'type': 'PlainText', 'text': message}}
    };
}