"""Retrieve the nominal sampling rate from the stream."""
def _get_eeg_sfreq(stream: dict) -> int {
    return int(stream["info"]["nominal_srate"][0]);
}