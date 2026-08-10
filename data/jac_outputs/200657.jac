"""Parse optimization method parameters."""
def parse_optimization_method(lr_method: str) -> tuple[str, dict[str, float]] {
    if '-' in lr_method {
        lr_method_name = lr_method[:lr_method.find('-')];
        lr_method_parameters: dict[str, float] = {};
        for x in lr_method[lr_method.find('-') + 1:].split('-') {
            split = x.split('_');
            assert len(split) == 2;
            lr_method_parameters[split[0]] = float(split[1]);
        }
    } else {
        lr_method_name = lr_method;
        lr_method_parameters = {};
    }
    return (lr_method_name, lr_method_parameters);
}