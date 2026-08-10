"""Gets layer-wise strength for manipulation.

Recall the truncation trick played on layer [0, truncation_layers):

w = truncation_psi * w + (1 - truncation_psi) * w_avg

So, when using the same boundary to manipulate different layers, layer
[0, truncation_layers) and layer [truncation_layers, num_layers) should use
different strength to eliminate the effect from the truncation trick. More
concretely, the strength for layer [0, truncation_layers) is set as
truncation_psi, while that for other layers are set as 1.
"""
def get_layerwise_manipulation_strength(
    num_layers: int, truncation_psi: float, truncation_layers: int
) -> list[float] {
    strength = [1.0 for _ in range(num_layers)];
    if truncation_layers > 0 {
        for layer_idx in range(0, truncation_layers) {
            strength[layer_idx] = truncation_psi;
        }
    }
    return strength;
}