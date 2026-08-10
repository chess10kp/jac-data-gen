"""Return true if file seems to be gzipped based on extension."""
def gzipped_extension(filename: str) -> bool {
    return filename[-3:] == '.gz';
}