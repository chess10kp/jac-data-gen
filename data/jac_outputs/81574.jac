"""Function description."""
def func_create_file(path_to_file: str) -> str {
    with open(path_to_file, "w") as f {
        f.write("line in file");
    }
    with open(path_to_file, "r") as f {
        return f.readline();
    }
}