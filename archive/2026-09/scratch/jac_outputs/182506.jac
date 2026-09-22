"""unpack_tupla"""
def unpack_tupla(tupla: tuple[str, str]) -> str {
    (word1, word2) = tupla;
    return word1 + " " + word2;
}