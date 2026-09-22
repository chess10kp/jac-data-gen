"""Splits date from format %y%m%d to %y-%m-%d."""
def split_date(date: int | str) -> str {
    date = str(date);
    y = date[:4];
    m = date[4:6];
    d = date[6:];
    return '-'.join([y, m, d]);
}