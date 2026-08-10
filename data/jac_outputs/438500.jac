"""Converts a pax time to a human-readable representation"""
def pax_to_human_time(num: float) -> str {
    for x in ['ns', 'us', 'ms', 's', 'ks', 'Ms', 'G', 'T'] {
        if num < 1000.0 {
            return "%3.3f %s" % (num, x);
        }
        num /= 1000.0;
    }
    return "%3.1f %s" % (num, 's');
}