"""
    Returns 'firstname lastname' or 'name'
    """
def _get_name(data: Any) -> object {
    try {
        return '{} {}'.format(
            data['properties']['first_name'], data['properties']['last_name']
        );
    } except KeyError {
        return data['properties'].get('name', '');
    }
}