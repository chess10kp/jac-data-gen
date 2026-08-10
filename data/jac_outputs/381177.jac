"""
    Convert file size to human readable format.
    """
def sizeof_fmt(num: Any) -> object {
    for x in ['bytes', 'KB', 'MB', 'GB', 'TB'] {
        if (num < 1024.0) {
            return "{0:.2f} {1}".format(num, x);
        }
        num /= 1024.0;
    }
}