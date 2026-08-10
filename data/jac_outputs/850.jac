"""
        Create an octave-repeating scale from a tonic note
        and a pattern of intervals

        Args:
            tonic: root note (midi note number)
            pattern: pattern of intervals (list of numbers representing
            intervals in semitones)
            octave: span of scale (in octaves)

        Returns:
            list of midi notes in the scale
    """
def create_scale(tonic: int, pattern: list[int], octave: int = 1) -> list[int] {
    assert sum(pattern) == 12;
    scale = [tonic];
    note = tonic;
    for o in range(octave) {
        for i in pattern {
            note += i;
            if note <= 127 {
                scale.append(note);
            }
        }
    }
    return scale;
}