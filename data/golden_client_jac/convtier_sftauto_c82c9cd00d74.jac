def process_message(message: Any) -> object {
    if (len(message) > 100) {
        return "Error: Message exceeds maximum character limit.";
    } else {
        return "Message processed successfully.";
    }
}



with entry {
    print(process_message('hello'));
}
