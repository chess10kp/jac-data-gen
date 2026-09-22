"""Is the given filename a wave file?"""
def _is_wav_file(filename: str) -> bool {
    return len(filename) > 4 and filename[-4:] == '.wav';
}