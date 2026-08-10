""" dtermine if a nonrigid rotation model is specified and further
        information is needed from the filesystem
    """
def nonrigid_rotations(spc_mod_dct_i: Any) -> object {
    rot_model = spc_mod_dct_i['rot']['mod'];
    return bool((rot_model == 'vpt2'));
}