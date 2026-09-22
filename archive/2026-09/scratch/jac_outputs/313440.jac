"""Take form 12 AND 15 to return [12, 15] for example"""
def either_side(text: str, delimiter: str = "and", `default: list[int] = [-1, -1]) -> list[int] {
    if delimiter in text {
        pos = text.index(delimiter);
        if text[pos - 1].isnumeric() and text[pos + 1].isnumeric() {
            return [int(text[pos - 1]), int(text[pos + 1])];
        } else {
            return `default;
        }
    } else {
        return `default;
    }
}