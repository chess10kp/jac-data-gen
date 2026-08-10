"""
        userScoreD is the dictionary that contains user scores.
        Returns the average user's score on a single item
    """
def averageScore(userScoreD: Any) -> object {
    sum = 0;
    len = 0;
    for score in userScoreD.values() {
        sum += score;
        len += 1;
    }
    return (sum / len);
}