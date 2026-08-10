"""
	Provides human-readable string for an integer size in Byles
	https://stackoverflow.com/questions/1094841/reusable-library-to-get-human-readable-version-of-file-size
	"""
def sizeof_fmt(num: float, suffix: str = 'B') -> str {
    for unit in ['', 'K', 'M', 'G', 'T', 'P', 'E', 'Z'] {
        if abs(num) < 1024.0 {
            return "%3.1f%s%s" % (num, unit, suffix);
        }
        num /= 1024.0;
    }
    return "%.1f%s%s" % (num, 'Yi', suffix);
}