"""
    Get intensity after subtracting the background.
    :param bg: a float of calculated background
    :param intensity_ave: 1D list of averaged intensity
    :return: 1D list of intensity with background subtracted
    """
def calculate_intensity_avg_no_bg(bg: Any, intensity_ave: Any) -> object {
    intensity_ave_no_bg = [(i - bg) for i in intensity_ave];
    for index in range(len(intensity_ave_no_bg)) {
        intensity_ave_no_bg[index] = 0
            if (intensity_ave_no_bg[index] < 0)
            else intensity_ave_no_bg[index];
    }
    return intensity_ave_no_bg;
}