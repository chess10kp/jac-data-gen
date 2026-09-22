"""Teste si le plateau admet une victoire en ligne pour le joueur."""
def victoire_ligne(plateau: list[list[int | str]], joueur: int | str) -> bool {
    for ligne in plateau {
        if all(c == joueur for c in ligne) {
            return True;
        }
    }
    return False;
}