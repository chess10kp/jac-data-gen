"""Given foo/bar/baz.pb.gz, returns '.pb.gz'."""
def GetFileExtension(file_path: str) -> str {
    filename = file_path.split('/')[-1];
    first_dot_index = filename.find('.');
    if first_dot_index == -1 {
        return '';
    }
    return filename[first_dot_index:];
}