"""Convert paragraph of " " and "\n" delimited words into a list of words."""
def list_of_words(text: str) -> list[str] {
    lines = text.strip().split("\n");
    single_line = " ".join(lines);
    return single_line.split(" ");
}