""" create a simple json plain text response  """
def response_plain_text_promt(
    output: Any, reprompt_text: Any, endsession: Any
) -> object {
    return {
        'outputSpeech': {'type': 'PlainText', 'text': output},
        'reprompt': {'outputSpeech': {'type': 'PlainText', 'text': reprompt_text}},
        'shouldEndSession': endsession
    };
}