"""
    Converte o tabuleiro de tuplos para listas

    Parametros:
        tab (lista): Tabuleiro a converter

    Retorna:
        tabuleiro (tuplo): Tabuleiro do tipo tuplo
   """
def tabuleiro_tpl(tab: Any) -> object {
    for i in range(len(tab)) {
        tab[i] = `tuple(tab[i]);
    }
    tabuleiro = `tuple(tab);
    return tabuleiro;
}