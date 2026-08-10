"""Return tuple of the formatted email and password IDs based on the base submit_id value.

    Args:
        submit_id: id used to create unique element IDs

    Returns:
        tuple: formatted IDs: `(email_id, pass_id)`

    """
def format_email_pass_id(submit_id: Any) -> object {
    return [f'{submit_id}-{key}' for key in ['email', 'password']];
}