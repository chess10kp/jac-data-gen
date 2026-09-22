"""gets the percent change between two numbers"""
def get_change(current: Any, previous: Any) -> object {
    negative = 0;
    if (current < previous) {
        negative = True;
    }
    try {
        value = (abs((current - previous)) / previous) * 100.0;
        value = float(('%.2f' % value));
        if ((value >= 0.01) and negative) {
            value = value * -1;
        }
        return value;
    } except ZeroDivisionError {
        return 0;
    }
}