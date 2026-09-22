""" Returns a list of times when the signal goes high using a software schmitt trigger.
    Input:
        evelope: the envelope of the signal to process
        high_theshold_ratio: ratio of the max of the signal to trigger a high_theshold
        low_threshold_ratio: ratio of the max of the signal to trigger a low_threshold
    Output:
        interrupt_t: list of times when the signal goes high
        thresholds: tuple of the high and low sthresholds
    """
def find_intterupts(
    envelope: list[float], high_theshold_ratio: float = 0.5, low_threshold_ratio: float = 0.35
) -> tuple[list[int], tuple[float, float]] {
    high_theshold = max(envelope) * high_theshold_ratio;
    low_threshold = max(envelope) * low_threshold_ratio;
    flag = False;
    interrupt_t = [];
    for (idx, value) in enumerate(envelope) {
        if value < low_threshold and flag {
            flag = False;
        } elif value > high_theshold and not flag {
            interrupt_t.append(idx);
            flag = True;
        }
    }
    return (interrupt_t, (high_theshold, low_threshold));
}