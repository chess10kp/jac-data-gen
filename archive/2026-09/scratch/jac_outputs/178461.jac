"""
    Add helpfulness scores and ratio as separate variables to a row
    :param row: A python dict containing data for a single review
    :return: A python dict containing the original data plus the number of users
    that rated this review as helpful, the total votes received by the review,
    and the ratio between the two. Reviews with no ratings have a NaN ratio
    """
def add_helpfulness(row: Any) -> object {
    helpful_pos = row['helpful'][0];
    helpful_tot = row['helpful'][1];
    helpful_ratio = (helpful_pos / helpful_tot) if helpful_tot else float("NaN");
    row.update(
        {
            'helpful_pos': helpful_pos,
            'helpful_tot': helpful_tot,
            'helpful_ratio': helpful_ratio
        }
    );
    return row;
}