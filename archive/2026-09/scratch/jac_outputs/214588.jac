"""
    Args:
        desired_wpm (int): the target words-per-minute value
                           you wish to achieve
        words_per_line (int): how many words per line your
                              test book contains on average
    Returns:
        seconds
    """
def time_per_line(desired_wpm: int, words_per_line: int) -> float {
    minute_fraction = words_per_line / (3 * desired_wpm);
    return minute_fraction * 60;
}