""" SNR in Octave ommits zeros at the end

    :return:
    """
def _repair_snr(snr: Any) -> object {
    snr = "{:.4f}".format(snr);
    while snr.endswith('0') {
        snr = snr[:-1];
    }
    if snr.endswith('.') {
        snr = snr[:-1];
    }
    return snr;
}