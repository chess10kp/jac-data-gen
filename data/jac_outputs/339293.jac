"""Intended for use with DataFrame.apply()

Returns an array with 'outcomert' converted from milliseconds to seconds if the 'study' variable is '3'"""
def clean_outcomert(row: dict[str, float | int]) -> float | int {
    if int(row['study']) >= 3 {
        return float(row['outcomert'] * 0.001);
    }
    return row['outcomert'];
}