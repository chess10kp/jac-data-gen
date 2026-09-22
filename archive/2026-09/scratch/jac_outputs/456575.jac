"""Make the authorization headers to communicate with endpoints which implement Auth0 authentication API.

    Args:
        auth_token (dict): a dict obtained from the Auth0 domain oauth endpoint, containing the signed JWT
            (JSON Web Token), its expiry, the scopes granted, and the token type.

    Returns:
        headers (dict): A dict representing the headers with necessary token information to talk to Auth0 authentication
            required endpoints.
    """
def make_auth_header(auth_token: Any) -> object {
    token_type = auth_token['token_type'];
    access_token = auth_token['access_token'];
    headers = {
        "Content-type": "application/json",
        "Authorization": "{token_type} {access_token}".format(
            token_type=token_type, access_token=access_token
        )
    };
    return headers;
}