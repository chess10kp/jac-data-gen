"""
    renvoie la position de la case en fontion du sens des lignes
    """
def position_case_ligne_motif(
    pos_ligne_motif: tuple[int, int], sens: str, colonne: int, ligne: int
) -> tuple[int, int] {
    (x_debut, y_debut) = pos_ligne_motif;
    if sens == "gauche" {
        x_case = x_debut - colonne * 25;
    } else {
        x_case = x_debut + colonne * 25;
    }
    (x_case, y_debut + ligne * 25)
}