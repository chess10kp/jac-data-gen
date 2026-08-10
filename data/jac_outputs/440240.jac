"""
    Return a package API data URL given a name, an optional version and a base
    repo API URL.

    For instance:
    >>> url = rubygems_api_url(name='turbolinks', version='1.0.2')
    >>> assert url == 'https://rubygems.org/api/v2/rubygems/turbolinks/versions/1.0.2.json'

    If no version, we return:
    >>> url = rubygems_api_url(name='turbolinks')
    >>> assert url == 'https://rubygems.org/api/v1/versions/turbolinks.json'

    Things we could return: a summary for the latest version, with deps
    https://rubygems.org/api/v1/gems/mqlight.json
    """
def rubygems_api_url(name: str, version: str | None = None) -> str | None {
    if not name {
        return;
    }
    if version {
        return f'https://rubygems.org/api/v2/rubygems/{name}/versions/{version}.json';
    } else {
        return f'https://rubygems.org/api/v1/versions/{name}.json';
    }
}