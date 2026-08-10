"""
    The message to be displayed to the user when they fail the LDAP validation

    Override this method if you want your own custom message

    Args:
        user (str): The user ID that was used for the LDAP search
        msg (errbot.backends.base.Message): The message from the bot that triggered the LDAP lookup
        groups (list): The list og group(s) in which the user was searched

    Returns:
        str: The formatted failure message

    """
def fail_message(user: Any, msg: Any, groups: Any) -> object {
    return f"Sorry, ```{user}``` is not permitted to execute the command ```{msg}``` as you are not a member of ```{','.join(
        groups
    )}```";
}