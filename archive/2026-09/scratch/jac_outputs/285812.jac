"""
    Return the `html_text` generated attribution stripped from timestamps: the
    timestamp is wrapped in italic block in the default template.
    """
def remove_timestamp(html_text: Any) -> object {
    return '\n'.join(
        x
        for x in html_text.splitlines()
        if not ('<i>' in x)
    );
}