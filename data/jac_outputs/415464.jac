"""Return a dictionary of extra labels for use in prompts to the user

    Intended use is in strings of the form "(l)ocal%(l)s".
    """
def partextras(labels: list[str] | None) -> dict[str, str] {
    if labels is None {
        return {"l": "", "o": ""};
    }
    return {"l": " [%s]" % labels[0], "o": " [%s]" % labels[1]};
}