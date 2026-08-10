"""
recuperer toute les tuiles de la zone centre de la meme couleur que
la tuile choisie
"""
def recup_centre(
    tuile_choisi: str, tuiles_zone_centre: list[str], tuile_permier_joueur: bool
) -> tuple[list[str], list[str], bool] {
    nombre = tuiles_zone_centre.count(tuile_choisi);
    for _ in range(nombre) {
        tuiles_zone_centre.remove(tuile_choisi);
    }
    resultat = [tuile_choisi] * nombre;
    if tuile_permier_joueur {
        resultat.append("premier_joueur");
        tuile_permier_joueur = False;
    }
    return (resultat, tuiles_zone_centre, tuile_permier_joueur);
}