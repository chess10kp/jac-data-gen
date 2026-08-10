"""Calculate indices of `affected_vars` in `input_vars`"""
def calc_var_indices(input_vars: list[object], affected_vars: list[object] | None) -> list[int] | None {
    if affected_vars is None {
        return None;
    }
    return [input_vars.index(var) for var in affected_vars];
}