""" Calculate average heart rate after specified date

    This function first sums all of the heart rates after the specified date.
    It then divides the summed heart rates by the total number of heart rate
    entries. The result is the sum of the heart rates after the entered time.

    :param hrs_after_time: a list of heart rate values that were entered after
    the specified time ("heart_rate_average_since")

    :returns: an integer indicating the average heart rate of the patient after
    a certain date
    """
def calculate_average_since(hrs_after_time: Any) -> object {
    total_entries = len(hrs_after_time);
    average_since = sum(hrs_after_time) / total_entries;
    return average_since;
}