"""Helper function to print execution times properly formatted."""
def print_execution_time(start: int | float, end: int | float) -> str {
    delta = end - start;
    hours = int(delta // 3600);
    rem = delta % 3600;
    minutes = int(rem // 60);
    seconds = int(rem % 60);
    return "{:0>2}:{:0>2}:{:0>2}".format(hours, minutes, seconds);
}