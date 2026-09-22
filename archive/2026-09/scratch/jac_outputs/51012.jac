"""Sort `results` by the message_id of the error messages."""
def sort_by_message(results: Any) -> object {
    return sorted(results, key=lambda (r: Any) { r['message_id']; });
}