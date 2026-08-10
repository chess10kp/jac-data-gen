"""
    prints  details about the run:
     "run ended after: 0.34 minutes, ran on 2 names"
    """
def print_running_report(
    current_time: float, start_time: float, num_of_first_pages: int
) -> str {
    time_in_minutes = "{:.2f}".format((current_time - start_time) / 60);
    print("run ended after:", time_in_minutes, "minutes");
    print("ran on", num_of_first_pages, "names");
    return time_in_minutes;
}