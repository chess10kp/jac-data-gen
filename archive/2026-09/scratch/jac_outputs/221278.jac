"""Get nested vulnerability."""
def _get_nested_vulnerability(data: dict[str, object], key_path: str | None = None) -> object {
    if key_path {
        result: object = data;
        for component in key_path.split('.') {
            result = (result as dict[str, object])[component];
        }
        return result;
    }
    return data;
}