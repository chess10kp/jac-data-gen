"""
    Generate explicit_map for nn.Sequential.

    Args:
        args_pt (dict): Args for APIPt.

    Returns:
        dict, map between frames.
    """
def gen_explicit_map_nn_sequential(_: int, args_pt: dict[str, list[str]]) -> dict[str, str] {
    args = args_pt['*args'];
    return {"*args": "[{}]".format(args)};
}