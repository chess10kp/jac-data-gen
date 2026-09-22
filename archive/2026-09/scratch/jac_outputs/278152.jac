"""pega uma lista de caracteres e converte em uma lista de inteiros"""
def convertCharToInt(strs: list) -> list {
    for (i, ch) in enumerate(strs) {
        strs[i] = ord(ch);
    }
    return strs;
}