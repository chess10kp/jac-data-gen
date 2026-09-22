"""Returns a list of words."""
def convert_to_list_of_words(lyrics: str) -> list[str] {
    lyrics.replace(',', '').lower().strip().split()
}