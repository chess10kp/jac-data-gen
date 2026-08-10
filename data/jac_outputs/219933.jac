"""
    Create a variant slider filter to be used in a trace filter sequence.

    Args:
        min_variant_group:
            An integer denoting the variant group on the lower bound.
        max_variant_group:
            An integer denoting the variant group on the upper bound.

    Returns:
        A dictionary containing the filter.
    """
def create_variant_slider_filter(
    min_variant_group: int, max_variant_group: int
) -> dict[str, str | int] {
    return {
        'type': 'variantSliderFilter',
        'min': min_variant_group,
        'max': max_variant_group
    };
}