"""
    Given a particular number of beats in a bar and grouping option, calculate
    which beats are strong beats.
    """
def calculate_strong_beats(beats_in_bar: int, grouping: list[int]) -> list[int] {
    strong_beats = [1];
    for beat in grouping {
        strong_beat = strong_beats[-1] + beat;
        if strong_beat < beats_in_bar {
            strong_beats.append(strong_beat);
        }
    }
    return strong_beats;
}