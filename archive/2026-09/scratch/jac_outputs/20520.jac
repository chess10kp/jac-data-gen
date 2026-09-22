"""Translate number time to str time"""
def _translate(num_time: Any) -> object {
    (minutes, remain_time) = ((num_time // 60), (num_time % 60));
    (str_minute, str_second) = map(str, (round(minutes), round(remain_time, 2)));
    str_second = (
        str_second.split('.')[0].rjust(2, '0'),
        str_second.split('.')[1].ljust(2, '0')
    );
    str_time = str_minute.rjust(2, '0') + f':{str_second[0]}.{str_second[1]}';
    return str_time;
}