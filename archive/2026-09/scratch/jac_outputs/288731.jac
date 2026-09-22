glob EXPECTED_ATTRS = (
    'name',
    'parent',
    'read',
    'describe',
    'read_configuration',
    'describe_configuration',
    'set'
);

"""Check if object satisfies bluesky 'movable' interface."""
def is_movable(`obj: object) -> bool {
    return all(hasattr(`obj, attr) for attr in EXPECTED_ATTRS);
}