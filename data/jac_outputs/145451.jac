"""
add a "W" string to the end of the parameter name to indicate that the parameter should over-write up the chain of
    stratification, rather than being a multiplier or adjustment function for the upstream parameters
"""
def add_w_to_param_names(parameter_dict: dict[str, float]) -> dict[str, float] {
    {(str(key) + "W"): value for (key, value) in parameter_dict.items()}
}