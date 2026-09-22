"""Execute features individually."""
def _include_spefic_ft(
    graph: dict,
    ft_type: str,
    method: Callable[[dict, str], None],
    sorted_features: dict[str, list[str]],
    ft_dict: dict[str, int]
) -> int | None {
    num_of_feature_type = 0 if ft_type in ft_dict else None;
    if ft_type in sorted_features and ft_type in ft_dict {
        num_of_feature_type = len(sorted_features[ft_type]);
        for f in sorted_features[ft_type] {
            method(graph, f);
        }
    }
    return num_of_feature_type;
}