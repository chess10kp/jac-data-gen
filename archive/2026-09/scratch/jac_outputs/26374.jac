"""Calculates the difference between the mean of own_team_scores and the mean of the combination of enemy_team_scores, neutral_scores and assassin_scores."""
def non_zero_mean_difference(
    own_team_scores: list[int],
    enemy_team_scores: list[int],
    neutral_scores: list[int],
    assassin_scores: list[int],
    weights: tuple[int, int, int, int] = (1, 1, 1, 1)
) -> float {
    (own_team_scores, enemy_team_scores, neutral_scores, assassin_scores) = (
        [x * weight for x in scores]
        for (weight, scores) in zip(
            weights,
            [own_team_scores, enemy_team_scores, neutral_scores, assassin_scores]
        )
    );
    good_scores = [score for score in own_team_scores if score != 0];
    bad_scores = [
        score
        for score in (enemy_team_scores + neutral_scores + assassin_scores)
        if score != 0
    ];
    mean_good_scores = sum(good_scores) / len(good_scores) if len(good_scores) > 0 else 0;
    mean_bad_scores = sum(bad_scores) / len(bad_scores) if len(bad_scores) > 0 else 0;
    return mean_good_scores - mean_bad_scores;
}