"""
    Extract user info from the client config specified.  Returns a dict
    that includes system key information.
    """
def extract_user_info(client_config: Any) -> object {
    if (
        ('system user' not in client_config)
        or ('name' not in client_config['system user'])
    ) {
        return None;
    }
    user_info = dict();
    user_info['system_key'] = dict(
        user=client_config['system user']['name'],
        access_key=client_config['system user']['access key'],
        secret_key=client_config['system user']['secret key']
    );
    return user_info;
}