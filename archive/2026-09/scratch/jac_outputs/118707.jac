"""
    :param highest: integer of highest exam score.
    :return: list of integer lower threshold scores for each D-A letter grade interval.
             For example, where the highest score is 100, and failing is <= 40,
             The result would be [41, 56, 71, 86]:


             41 <= "D" <= 55 14
             56 <= "C" <= 70 14
             71 <= "B" <= 85 14
             86 <= "A" <= 100 14
    """
def letter_grades(highest: Any) -> object {
    thresholds = [];
    intervals = [];
    failing = 41;
    interval = 0;
    interval = round(((highest - failing) / 4));
    intervals.append(failing);
    intervals.append((failing + (interval * 1)));
    intervals.append((failing + (interval * 2)));
    intervals.append((failing + (interval * 3)));
    return intervals;
}