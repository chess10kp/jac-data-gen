import re;

"""Parses duration value string 'Xhr', 'Ymin' or 'Zsec' and returns (X::Y::Z) as seconds."""
def parse_duration(row: str) -> int {
    def filter_digits(s: str) -> str {
        return "".join(re.findall('\d+', s));
    }
    seconds = 0;
    if 'hr' in row {
        (hr, row) = row.split('hr');
        seconds += int(filter_digits(hr)) * 3600;
    }
    if 'min' in row {
        (min, row) = row.split('min');
        seconds += int(filter_digits(min)) * 60;
    }
    if 'sec' in row {
        (sec, _) = row.split('sec');
        seconds += int(filter_digits(sec));
    }
    return seconds;
}