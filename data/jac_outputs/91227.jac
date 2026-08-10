"""For image data scaled between [-1,1],
    rescale to [0,1] * scale_multiplier (e.g. 255 for RGB images)
    """
def tanh_to_sig_scale(tanh_input: float, scale_multiplier: float = 1.0) -> float {
    return (tanh_input + 1.0) / 2.0 * scale_multiplier;
}