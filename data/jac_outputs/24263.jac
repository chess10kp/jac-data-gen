"""
    Thresholds taken from https://en.wikipedia.org/wiki/Flesch%E2%80%93Kincaid_readability_tests
    """
def get_reading_level_from_flesch(flesch_score: float) -> str {
    if flesch_score < 30 {
        return "Very difficult to read";
    } elif flesch_score < 50 {
        return "Difficult to read";
    } elif flesch_score < 60 {
        return "Fairly difficult to read";
    } elif flesch_score < 70 {
        return "Plain English";
    } elif flesch_score < 80 {
        return "Fairly easy to read";
    } elif flesch_score < 90 {
        return "Easy to read";
    } else {
        return "Very easy to read";
    }
}