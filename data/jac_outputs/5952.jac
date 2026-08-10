"""In this preliminary version, the outside information is ignored."""
def params_schedule_fn_constant_09_01(outside_information: dict[str, float] | list[float] | None) -> dict[str, tuple[int, int] | float | bool | None | list[dict[str, list[str]]]] {
    mdp_default_gen_params = {
        "inner_shape": (7, 5),
        "prop_empty": 0.9,
        "prop_feats": 0.1,
        "start_all_orders": [{"ingredients": ["onion", "onion", "onion"]}],
        "display": False,
        "rew_shaping_params": None
    };
    return mdp_default_gen_params;
}