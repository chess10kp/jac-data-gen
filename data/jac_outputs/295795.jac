"""Renvoie le nombre de case remplie dans la ligne motif."""
def avoir_ind_courant(ligne: list[str]) -> int {
    ind_courant = 0;
    for cell in ligne {
        if cell != "" {
            ind_courant += 1;
        }
    }
    return ind_courant;
}