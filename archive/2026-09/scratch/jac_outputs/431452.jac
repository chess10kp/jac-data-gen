"""Initialize parameters for different levels of the network."""
def initialize_hyper_parameters(layer_acts: list[Callable], learning_rate: float) -> dict[str, dict[int, Callable] | float] {
    hyper_parameters = {};
    activations = {};
    L = len(layer_acts);
    for l in range(0, L) {
        activations[l + 1] = layer_acts[l];
    }
    hyper_parameters["activations"] = activations;
    hyper_parameters["learning_rate"] = learning_rate;
    return hyper_parameters;
}