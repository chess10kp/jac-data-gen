"""Gather dimension names from variables as a set."""
def get_dim_names_for_variables(variables: list) -> set[str] {
    return {dim for v in variables for dim in v.dims};
}