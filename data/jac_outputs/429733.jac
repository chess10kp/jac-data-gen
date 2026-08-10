"""Used in tests that have recursive $refs
    """
def node_spec() -> object {
    return {
        'type': 'object',
        'properties': {
            'name': {'type': 'string'},
            'child': {'$ref': '#/definitions/Node'}
        },
        'required': ['name']
    };
}