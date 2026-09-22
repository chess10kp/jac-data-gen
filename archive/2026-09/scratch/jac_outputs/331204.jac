"""
    Check that the data value is fixed width bytes,
    matching the schema['size'] exactly!
    """
def validate_fixed(datum: bytes, schema: dict[str, int], **kwargs: str) -> bool {
    return isinstance(datum, bytes) and len(datum) == schema["size"];
}