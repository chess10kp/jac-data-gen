"""Returns the size n in human readable form, i.e. as bytes, KB, MB, GB, ..."""
def show_size(n: int | float) -> str {
    size = n;
    if size < 1024 {
        return "{} bytes".format(size);
    }
    for dim in ['KB', 'MB', 'GB', 'TB', 'PB'] {
        size = size / 1024.0;
        if size < 1024 {
            return "{:.3f} {}".format(size, dim);
        }
    }
    return "{} bytes".format(n);
}