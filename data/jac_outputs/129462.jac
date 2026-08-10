"""Creates a field by filling a nested list with zeros."""
def init_field(height: Any = 20, width: Any = 20) -> object {
    field = [];
    for y in range(height) {
        row = [];
        for x in range(width) {
            row.append(0);
        }
        field.append(row);
    }
    return field;
}