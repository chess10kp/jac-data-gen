"""Encodes all strings using encoding, default ascii."""
def deep_encode(e: dict[str, str | int | float | bool | list | dict] | list[str | int | float | bool | list | dict] | str | int | float | bool | None, encoding: str = 'ascii') -> dict[str, str | int | float | bool | bytes | list | dict] | list[str | int | float | bool | bytes | list | dict] | bytes | int | float | bool | None {
    if isinstance(e, dict) {
        return dict((i, deep_encode(j, encoding)) for (i, j) in e.items()) as dict[str, str | int | float | bool | bytes | list | dict];
    } elif isinstance(e, list) {
        return [deep_encode(i, encoding) for i in e] as list[str | int | float | bool | bytes | list | dict];
    } elif isinstance(e, str) {
        return e.encode(encoding);
    }
    return e;
}