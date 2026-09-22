""" Inject bdd_vars so they becomes available in play
        fixture """
def bdd_vars(bdd_vars: dict[str, str], variables: dict[str, str], skin: str, data_base_path: str) -> dict[str, str] {
    bdd_vars['data_base_path'] = data_base_path;
    return bdd_vars;
}