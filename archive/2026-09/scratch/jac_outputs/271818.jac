"""
This is a helper function to normalise periodtype
to always reflect the number of days
"""
def normalise_days(periodType: str, value: int) -> int {
    periodType = periodType.lower();
    if periodType == 'weeks' {
        return value * 7;
    } elif periodType == 'months' {
        return value * 30;
    } else {
        return value;
    }
}