"""Convert d-m-y to y-m-d where original data recorded day in year format
    """
def dash_to_slash(datetime_str: str) -> str {
    (date, time) = datetime_str.split();
    date_arr = date.split('-');
    if len(date_arr[0]) > 2 {
        date_arr[0] = date_arr[0][-2:];
    }
    '/'.join(date_arr) + ' ' + time
}