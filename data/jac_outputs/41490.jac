"""
    Teste si le plateau admet une victoire en diagonale pour le joueur.
    """
def victoire_diagonale(plateau: Any, joueur: Any) -> object {
    if (
        all((plateau[(2 - i)][i] == joueur) for i in range(3))
        or all((plateau[i][i] == joueur) for i in range(3))
    ) {
        return True;
    }
    return False;
}