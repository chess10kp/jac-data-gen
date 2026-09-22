"""Create the list of feature names depending on the number of principal components."""
def get_features_name(npcs: int) -> list[str] {
    names_root = [('coeff' + str(i + 1) + '_') for i in range(npcs)] + ['residuo_', 'maxflux_'];
    return [i + j for j in ['g', 'r'] for i in names_root];
}