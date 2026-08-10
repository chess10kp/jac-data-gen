"""
    Essa funcao recebe uma lista de palavras e devolve o numero de palavras
    diferentes utilizadas.
    """
def n_palavras_diferentes(lista_palavras: Any) -> object {
    freq = `dict();
    for palavra in lista_palavras {
        p = palavra.lower();
        if (p in freq) {
            freq[p] += 1;
        } else {
            freq[p] = 1;
        }
    }
    return len(freq);
}