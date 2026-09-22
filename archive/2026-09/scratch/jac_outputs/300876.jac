"""
Take an iterable collection and returns the collection as a string
formatted using the Oxford comma
"""
def comma_code(collection: list[str | int | float]) -> str {
    if len(collection) == 0 {
        return '';
    } elif len(collection) == 1 {
        return str(collection[0]);
    }
    return f"{', '.join([str(item) for item in collection[:-1]])}, and {collection[-1]}";
}