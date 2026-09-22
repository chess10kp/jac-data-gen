"""Convert file size to human readable format."""
def sizeof_fmt(num: float) -> str | None {
    for x in ['b', 'K', 'M', 'G', 'T'] {
        if num < 1024.0 {
            return "{0:.2f}{1}".format(num, x);
        }
        num /= 1024.0;
    }
}