"""get gear ratio

    Args:
        g (int): gear
        gear_ratios (dict): mapping of gear to gear ratio

    Returns:
        [float]: gear ratio
    """
def get_gear_ratio(g: int, gear_ratios: dict) -> object {
    return gear_ratios[g]['ratio'];
}