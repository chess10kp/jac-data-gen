"""
    Builds a response with speech part and Alexa appcard contents
    :param text: text to be spoken
    :param card: text for the app card
    :return: JSON object to be returned
    """
def response_creator(text: Any, card: Any) -> object {
    text_item = {"type": "PlainText", "text": text};
    card_item = {"type": "Simple", "title": "Stop Info", "content": card};
    reprompt = {
        "outputSpeech": {
            "text": "Which stop do you want to know about?",
            "type": "PlainText"
        }
    };
    response = {
        "version": "1.0",
        "response": {
            "outputSpeech": text_item,
            "card": card_item,
            "reprompt": reprompt,
            "shouldEndSession": True
        }
    };
    return response;
}