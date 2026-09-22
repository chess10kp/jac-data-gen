"""
    Wraps a list of message into a discord markdown block
    :param [str] lines:
    :return: The wrapped string
    :rtype: str
    """
def generate_discord_markdown_string(lines: Any) -> object {
    output = ["```markdown"] + lines + ["```"];
    return "\n".join(output);
}