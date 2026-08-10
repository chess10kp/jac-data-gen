"""Convert a scisample dictionary to a maestro dictionary"""
def _convert_dict_to_maestro_params(samples: list[dict[str, str | int | float | bool]]) -> dict[str, dict[str, str | list[str | int | float | bool]]] {
    keys = list(samples[0].keys());
    parameters = {};
    for key in keys {
        parameters[key] = {};
        parameters[key]["label"] = str(key) + ".%%";
        values = [sample[key] for sample in samples];
        parameters[key]["values"] = values;
    }
    return parameters;
}