"""Korjaa sanalinkit."""
def replace_sanalinkki(text: str, words: dict[str, str]) -> str {
    for key in words {
        text = text.replace("#sanalinkki_{}".format(key), "#" + words[key]);
    }
    return text;
}