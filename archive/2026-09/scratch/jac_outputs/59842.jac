import calendar;

"""
>>> calendar_module('08 05 2015')
'WEDNESDAY'
"""
def calendar_module(raw_str: str) -> str {
    (month, day, year) = map(int, raw_str.split());
    num_day = calendar.weekday(year, month, day);
    return calendar.day_name[num_day].upper();
}