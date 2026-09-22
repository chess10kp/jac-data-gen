"""
Convert a set of parameters into the data types used to represent them.
Returned result has the same structure as the parameters.
"""
def _recursive_parameter_structure(default_parameters: dict | tuple | float | int) -> dict | tuple | type {
    if isinstance(default_parameters, dict) {
        return {
            key: _recursive_parameter_structure(value)
            for (key, value) in default_parameters.items()
        };
    } elif isinstance(default_parameters, tuple) {
        return tuple(
            _recursive_parameter_structure(value) for value in default_parameters
        );
    } elif isinstance(default_parameters, float) {
        return float;
    } elif isinstance(default_parameters, int) {
        return int;
    }
    raise TypeError(
        'Unaccepted type in experiment parameters: type "%s".'
        % type(default_parameters).__name__
    );
}