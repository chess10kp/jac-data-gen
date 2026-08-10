"""survival_score = 80% * survival time score + 20% * win place score"""
def survival_score(timeSurvived: int, duration: int, winPlace: int) -> int {
    survival = timeSurvived / duration * 100;
    if winPlace == 1 {
        win_place = 100;
    } else {
        win_place = 100 - winPlace;
    }
    survival_score = int(survival * 0.8 + win_place * 0.2);
    if survival_score < 50 {
        survival_score = 50;
    }
    return survival_score;
}