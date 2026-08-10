"""Calculates drop prob depending on the current layer."""
def _calc_shakedrop_mask_prob(
    curr_layer: int, total_layers: int, mask_prob: float
) -> float {
    return 1 - (float(curr_layer) / total_layers) * mask_prob;
}