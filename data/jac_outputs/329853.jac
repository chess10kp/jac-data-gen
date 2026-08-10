"""Calculates percentage to a certain accuracy"""
def percent_used(maximum: Any, used: Any, accuracy: Any = 2) -> object {
    int_percent = round(((used / maximum) * 100), accuracy);
    percentage = str(int_percent) + "%";
    return percentage;
}