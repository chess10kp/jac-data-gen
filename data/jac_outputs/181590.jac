"""Transform inp into a dictionary copy."""
def make_dict(inp: dict[str, int | str | float | bool]) -> dict[str, int | str | float | bool] {
    import copy;
    local_tmp = copy.deepcopy(inp);
    local_input = {};
    local_input.update(local_tmp);
    return local_input;
}