"""
       Generates a dict which contains the target name as key, and the score '1.00' and a p-value 'foo'
       as a set in the value of the dict. This dict will be used for the targets comparison
    """
def generate_targets_dict_for_comparison(targets_list: Any) -> object {
    targets_dict = {};
    for target in targets_list {
        targets_dict[target] = (1.0, "foo");
    }
    return targets_dict;
}