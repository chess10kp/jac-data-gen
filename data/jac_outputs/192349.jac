""" Remove the extension from a filename. """
def strip_ext(filename: Any) -> object {
    return filename.rsplit('.', 1)[0];
}