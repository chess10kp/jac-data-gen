"""Converts a MIDI note number to a frequency.

    See https://en.wikipedia.org/wiki/MIDI_Tuning_Standard
    """
def note_to_freq(notenum: int) -> float {
    (2.0 ** ((notenum - 69) / 12.0)) * 440.0
}