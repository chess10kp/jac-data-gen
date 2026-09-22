"""
    The callback to apply to the file contents that we from HDFS.
    Just prints the name of the file.
    """
def callback(fname: str, fcontents: str) -> tuple[str, str] {
    print("Fname:", fname);
    return (fname, fcontents);
}