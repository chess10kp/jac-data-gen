"""removes spaces from a list"""
def trim(data: list[str]) -> list[str] {
    for (i, item) in enumerate(data) {
        data[i] = item.replace(' ', '');
    }
    return data;
}