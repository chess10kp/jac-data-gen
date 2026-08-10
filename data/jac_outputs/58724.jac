"""Fetches the roles for a user from the Gateway.

    This may not be the currently logged in user. Requires the password
    for that user. If the authentication profile name is omitted, then
    the current project's default authentication profile is used.

    Args:
        username (str): The username to fetch roles for.
        password (str): The password for the user.
        authProfile (str): The name of the authentication profile to run
            against. Optional. Leaving this out will use the project's
            default profile.
        timeout (int): Timeout for client-to-gateway communication.
            Optional. (default: 60,000ms)

    Returns:
        tuple[str]: A list of the roles that this user has, if the user
            authenticates successfully. Otherwise, returns None.
    """
def getUserRoles(
    username: Any, password: Any, authProfile: Any = "", timeout: Any = 60000
) -> object {
    print(username, password, authProfile, timeout);
    return ("Administrator", "Developer");
}