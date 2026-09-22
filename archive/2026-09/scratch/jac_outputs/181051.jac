"""Create file name."""
def create_file_name(num: int, length: int) -> str {
    "dump-" + "0" * (len(str(length)) - len(str(num))) + str(num) + ".jpg"
}