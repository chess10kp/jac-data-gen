"""Multiply parameter dict values by multiplier."""
def change_parameter_unit(parameter_dict: dict[str, float], multiplier: float) -> dict[str, float] {
    return {param_key: param_value * multiplier for (param_key, param_value) in parameter_dict.items()};
}