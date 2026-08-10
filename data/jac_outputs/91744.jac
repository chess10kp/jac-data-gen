"""Removes the name prefix in checkpoint.

    Basically, when the model is deployed in parallel, the prefix `module.` will
    be added to the saved checkpoint. This function is used to remove the
    prefix, which is friendly to checkpoint loading.
    """
def _strip_state_dict_prefix(state_dict: dict[str, str], prefix: str = 'module.') -> dict[str, str] {
    if not all(key.startswith(prefix) for key in state_dict.keys()) {
        return state_dict;
    }
    stripped_state_dict = dict();
    for key in state_dict {
        stripped_state_dict[key.replace(prefix, '')] = state_dict[key];
    }
    return stripped_state_dict;
}