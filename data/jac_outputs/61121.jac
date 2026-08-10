"""Formats date to yyyy-mm-dd. Returns date as string."""
def date_format(date_str: str) -> str {
    day = '01';
    split_date = date_str.split('/');
    if len(split_date) < 2 {
        (month, year) = ('01', split_date[0]);
    } else {
        (month, year) = split_date;
    }
    return f'{year}-{month}-{day}';
}