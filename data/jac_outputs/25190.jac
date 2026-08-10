""" Compute a new odds of an outcome """
def update_odds_with_evidence(prevalence: dict[int, float], testPower: dict[int, dict[int, float]], evdnc: int) -> dict[int, float] {
    evPos = evdnc;
    evNeg = 1 - evdnc;
    oddsPos = prevalence[evPos] / prevalence[evNeg] * testPower[evdnc][evPos] / testPower[evdnc][evNeg];
    oddsNeg = float('nan');
    if oddsPos > 1 {
        oddsNeg = 1.0;
    } elif oddsPos > 0 {
        oddsNeg = 1 / oddsPos;
        oddsPos = 1.0;
    }
    return {evPos: oddsPos, evNeg: oddsNeg};
}