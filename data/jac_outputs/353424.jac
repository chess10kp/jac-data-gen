"""Returns the index of the image"""
def get_file_index(file: str) -> int {
    int(file.split('_')[-1].split('.')[0])
}