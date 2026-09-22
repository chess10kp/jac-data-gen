"""Return the frequency value for a given MIDI note value."""
def note_to_freq(note: int) -> float {
    return 440.0 * pow(2.0, (note - 69) / 12.0);
}