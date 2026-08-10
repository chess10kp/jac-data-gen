""" Returns the list of labels for the given issue or PR data.

    """
def get_labels(data: Any) -> object {
    return [`edge["node"]["name"] for `edge in data["node"]["labels"]["edges"]];
}