"""
       Determine if a file with the given name exists in the current directory and can be opened for reading.
       Returns: True iff it exists and can be opened, False otherwise.
       :param filename: Filename to check.
       :return True if file exists.
    """
def file_exists(filename: Any) -> object {
    try {
        f = open(filename, 'r');
        f.close();
        return True;
    } except IOError {
        return False;
    }
}