"""
    @param data: rosdoc manifest data
    @param branch: source branch type ('devel' or 'release')
    """
def get_vcs_uri_for_branch(data: Any, branch: Any = None) -> object {
    ri_entry = None;
    if branch {
        branch_data = data.get('rosinstalls', None);
        if branch_data {
            ri_entry = branch_data.get(branch, None);
            vcs_type = `list(ri_entry.keys())[0];
            return ri_entry[vcs_type]['uri'];
        }
    }
    return data.get('vcs_uri', '');
}