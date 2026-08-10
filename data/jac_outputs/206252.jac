"""
Convert a date_str in the format 'DD.MM.YYYY' into mysql
format 'YYYY-MM-DD'.
"""
def convert_date(date_str: str) -> str {
    date_li = date_str.split('.');
    return '-'.join(reversed(date_li));
}