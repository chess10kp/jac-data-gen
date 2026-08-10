"""extract filename given path"""
def find_filename(path_to_file: str) -> str {
    return path_to_file.split('/')[-1];
}