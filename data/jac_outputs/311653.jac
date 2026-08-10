"""get number of groups used by GroupNorm, based on number of channels."""
def get_group_gn(dim: int, dim_per_gp: int, num_groups: int) -> int {
    assert dim_per_gp == -1 or num_groups == -1, "GroupNorm: can only specify G or C/G.";
    if dim_per_gp > 0 {
        assert dim % dim_per_gp == 0, "dim: {}, dim_per_gp: {}".format(dim, dim_per_gp);
        group_gn = dim // dim_per_gp;
    } else {
        assert dim % num_groups == 0, "dim: {}, num_groups: {}".format(dim, num_groups);
        group_gn = num_groups;
    }
    return group_gn;
}