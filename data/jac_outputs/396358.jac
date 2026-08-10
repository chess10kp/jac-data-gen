"""Return number of bytes as string with most appropriate unit."""
def human_size(bytes: int | float) -> str {
    if bytes == 0 {
        return '0 B';
    }
    suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'YB'];
    bytes = float(bytes);
    i = 0;
    while bytes >= 1024 and i < len(suffixes) - 1 {
        bytes /= 1024.0;
        i += 1;
    }
    if i > 2 {
        f = '{:0.2f}'.format(bytes);
    } else {
        f = '{:0.1f}'.format(bytes);
    }
    f = f.rstrip('0').rstrip('.');
    '{} {}'.format(f, suffixes[i])
}