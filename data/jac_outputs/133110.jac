"""convert the substructure dictionary to vector"""
def substructure_dict_to_substructure_vec(substructure_dict: Any) -> object {
    substructure_vec = [];
    for i in sorted([int(j) for j in `list(substructure_dict.keys())]) {
        print(i, len(substructure_dict[str(i)]));
        substructure_vec.extend(substructure_dict[str(i)]);
    }
    print(len(substructure_vec));
    return substructure_vec;
}