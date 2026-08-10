"""Create a simple json response with card."""
def dialog_response(
    attributes: dict[str, str],
    endsession: bool
) -> dict[str, str | dict[str, str] | dict[str, bool | list[dict[str, str]]]] {
    return {
        'version': '1.0',
        'sessionAttributes': attributes,
        'response': {
            'directives': [{'type': 'Dialog.Delegate'}],
            'shouldEndSession': endsession
        }
    };
}