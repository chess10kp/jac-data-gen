"""Returns data in a database cursor object as list."""
def unpack(cursor: list[object]) -> list[object] {
    return [data for data in cursor];
}