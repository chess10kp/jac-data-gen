"""Classify an inappropriateness probability into discreet categories."""
def score_to_flag(score: float) -> int {
    assert isinstance(score, float), f'score type ({type(score)}) not float.';
    assert score >= 0.0 and score <= 1.0, f'Score ({score}) outside acceptable range (0->1).';
    if score < 0.2 {
        return 0;
    } elif score < 0.95 {
        return 1;
    } else {
        return 2;
    }
}