"""Calculates the number of models to learn based on targets and potential targets."""
def _nb_models_and_deficit(nb_targets: int, potential_targets: list[str]) -> tuple[int, int] {
    nb_potential_targets = len(potential_targets);
    nb_models = nb_potential_targets // nb_targets;
    nb_leftover_targets = nb_potential_targets % nb_targets;
    return (nb_models, nb_leftover_targets);
}