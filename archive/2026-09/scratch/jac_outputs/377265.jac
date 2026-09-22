"""Formats time into mm:ss:xx"""
def format_time(seconds: float) -> str {
    minutes = seconds // 60;
    seconds = seconds % 60;
    centi = "{:.2f}".format(seconds % 1)[1:];
    return "{:02d}:{:02d}{}".format(int(minutes), int(seconds), centi);
}