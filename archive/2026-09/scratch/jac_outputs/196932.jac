"""Check whether a file path refers to a __init__.py or __init__.pyc file."""
def _is_package_init(path: str) -> bool {
    return path.lower().endswith(('__init__.py', '__init__.pyc'));
}