"""Convert a Mopidy proxy config to the commonly used proxy string format.

    Outputs ``scheme://host:port``, ``scheme://user:pass@host:port`` or
    :class:`None` depending on the proxy config provided.

    You can also opt out of getting the basic auth by setting ``auth`` to
    :class:`False`.
    """
def format_proxy(proxy_config: dict[str, str | int | None], auth: bool = True) -> str | None {
    if not proxy_config.get('hostname') {
        return None;
    }
    port = proxy_config.get('port', 80);
    if port < 0 {
        port = 80;
    }
    if proxy_config.get('username') and proxy_config.get('password') and auth {
        template = '{scheme}://{username}:{password}@{hostname}:{port}';
    } else {
        template = '{scheme}://{hostname}:{port}';
    }
    return template.format(
        scheme=(proxy_config.get('scheme') or 'http'),
        username=proxy_config.get('username'),
        password=proxy_config.get('password'),
        hostname=proxy_config['hostname'],
        port=port
    );
}