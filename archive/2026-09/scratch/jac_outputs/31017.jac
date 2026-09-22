def dict_to_parameter_list(d: dict[str, object]) -> list[dict[str, object]] {
    [{'name': k, 'value': v} for (k, v) in d.items()]
}