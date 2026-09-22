"""Convert spatpix from an arbitrary frame to nat coordinates in SUBSTRIP256.

    :param spatpix: spatpix coordinates in an arbitrary coordinate frame.
    :param frame: the input coordinate frame.
    :param subarray: the input coordinate subarray.
    :param oversample: the oversampling factor of the input coordinates.

    :type spatpix: array[float]
    :type frame: str
    :type subarray: str
    :type oversample: int

    :returns: spatpix_ref - the input coordinates transformed to nat coordinate frame and SUBSTRIP256 subarray.
    :rtype: array[float]
    """
def spatpix_frame_to_ref(
    spatpix: Any, frame: Any = 'dms', subarray: Any = 'SUBSTRIP256', oversample: Any = 1
) -> object {
    if ((frame == 'nat') & (subarray == 'SUBSTRIP256')) {
        spatpix_ref = spatpix;
    } elif ((frame == 'dms') & (subarray == 'SUBSTRIP256')) {
        spatpix_ref = (255 * oversample) - spatpix;
    } elif ((frame == 'sim') & (subarray == 'SUBSTRIP256')) {
        spatpix_ref = spatpix;
    } elif ((frame == 'nat') & (subarray == 'SUBSTRIP96')) {
        spatpix_ref = spatpix + (150 * oversample);
    } elif ((frame == 'dms') & (subarray == 'SUBSTRIP96')) {
        spatpix_ref = (245 * oversample) - spatpix;
    } elif ((frame == 'sim') & (subarray == 'SUBSTRIP96')) {
        spatpix_ref = spatpix + (150 * oversample);
    } else {
        raise ValueError(
            'Unknown coordinate frame or subarray: {} {}'.format(frame, subarray)
        );
    }
    return spatpix_ref;
}