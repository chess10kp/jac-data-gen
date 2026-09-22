"""THIS SECTION REMAINS FOR TESTING PURPOSES

    Function used for the segmentation of the signal into smaller parts of audio (blocks). This implementation
    has been modified in order to make a simpler version of the original one. After the tests, it has been proven that
    this algorithm is way faster than the original, it reduces some uncertainty and the number of blocks remains the
    same in most cases. Also, it treats the void that leaves the standard in blocks that have samples that ar out
    of bounds.

    Parameters
    ----------
    band_pass_signal_hr: numpy.array
        Time signal values of the input signal.

    sb: int
        Block size.

    sh: int
        Hop size.

    dim: int
        Signal dimensions.

    Returns
    -------
    block_array: List[List[float]]
        Array list of blocks in which the signal has been segmented.
    """
def segmentation_blocks_test_a(
    band_pass_signal_hr: Any, sb: Any, sh: Any, dim: Any
) -> object {
    block_array = [
        band_pass_signal_hr[block_s:(block_s + sb)]
        for block_s in range(0, len(band_pass_signal_hr), sh)
    ];
    return block_array;
}