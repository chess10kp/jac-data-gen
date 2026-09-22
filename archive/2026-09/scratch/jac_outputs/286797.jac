"""The points allowed score logic generator based on standard D/ST fantasy football scoring."""
def points_allowed_score(points: float) -> int {
    if points == 0 {
        score = 10;
    } elif points < 7 {
        score = 7;
    } elif points < 14 {
        score = 4;
    } elif points < 18 {
        score = 1;
    } elif points < 28 {
        score = 0;
    } elif points < 35 {
        score = -3;
    } else {
        score = -4;
    }
    return score;
}