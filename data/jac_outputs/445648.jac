"""
returns the words with the least and maximum length.
Use min and max and pass another function as argument
"""
def get_min_max_words(input: list[str]) -> tuple[str, str] {
    (min(input, key=len), max(input, key=len))
}