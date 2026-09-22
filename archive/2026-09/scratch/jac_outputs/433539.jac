"""
    replace the user input with correct html code. so that we can submit the data to Jama in an expected format
    """
def prepare_html(payload: str) -> str {
    payload.replace('\n', '<br>')
}