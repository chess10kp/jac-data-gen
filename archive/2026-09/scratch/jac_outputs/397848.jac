"""utf encode every element of a list."""
def utf_encode_list(text: list[str]) -> list[bytes] {
    [x.encode('utf-8') for x in text]
}