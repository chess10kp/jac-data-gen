"""Compute center frequency from a MIDI pitch value."""
def f_pitch(p: float, pitch_ref: float = 69, freq_ref: float = 440.0) -> float {
    return 2 ** ((p - pitch_ref) / 12) * freq_ref;
}