"""
    Gets transition frequency color

    Parameters
    ----------
    trans_count
        Current transition count
    min_trans_count
        Minimum transition count
    max_trans_count
        Maximum transition count

    Returns
    ----------
    color
        Frequency color for visible transition
    """
def get_trans_freq_color(
    trans_count: float,
    min_trans_count: float,
    max_trans_count: float
) -> str {
    trans_base_color = int(
        255 - 100 * (trans_count - min_trans_count) / (max_trans_count - min_trans_count + 0.00001)
    );
    trans_base_color_hex = str(hex(trans_base_color))[2:].upper();
    return "#" + trans_base_color_hex + trans_base_color_hex + "FF";
}