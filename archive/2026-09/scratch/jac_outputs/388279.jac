"""Assemble a model list for a specific task based on the ranking."""
def get_config_list(ranking: list[tuple[str, float]], ckpt_path2is_3class: dict[str, bool]) -> list[dict[str, str | bool | float]] {
    config_list = [];
    for (ckpt_path, value) in ranking {
        is3_class = ckpt_path2is_3class[ckpt_path];
        ckpt_info = {
            'ckpt_path': str(ckpt_path),
            'is_3class': is3_class,
            'value': value
        };
        config_list.append(ckpt_info);
    }
    return config_list;
}