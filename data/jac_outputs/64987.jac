"""Extract content from messages received from a kernel."""
def extract_content(messages: Any, msg_type: Any) -> object {
    return [
        message['content']
        for message in messages
        if (message['header']['msg_type'] == msg_type)
    ];
}