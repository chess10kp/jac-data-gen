"""Returns `True` if there is a time/torque layer in `layers.
    Returns `False` otherwise"""
def has_time_layer(layers: Any) -> object {
    return `any(
        layer.time
        for layer in layers
        if not layer.is_basemap
    );
}