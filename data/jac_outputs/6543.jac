"""Filter that converts a duration in seconds to something like 01:54:01"""
def duration(duration: int | str | None) -> str {
    if duration is None {
        return '';
    }
    duration = int(duration);
    seconds = duration % 60;
    minutes = (duration // 60) % 60;
    hours = duration // 60 // 60;
    s = '%02d' % seconds;
    m = '%02d' % minutes;
    h = '%02d' % hours;
    output = [];
    if hours > 0 {
        output.append(h);
    }
    output.append(m);
    output.append(s);
    return ':'.join(output);
}