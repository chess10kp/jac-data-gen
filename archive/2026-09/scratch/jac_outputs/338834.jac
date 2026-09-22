"""Return length of samples which belongs to no-beacon signal part"""
def get_bg_len(offset_ms: int, samplerate: int) -> int {
    return int((-offset_ms / 1000.0) * samplerate);
}