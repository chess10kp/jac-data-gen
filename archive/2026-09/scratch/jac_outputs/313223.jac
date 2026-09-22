"""Find the lowest shared parent directory path, or None if none exists."""
def find_common_directory(directory_x: str, directory_y: str) -> str | None {
    x_path = directory_x.split("\\");
    y_path = directory_y.split("\\");
    result_path = "";
    ticker = len(x_path);
    if ticker > len(y_path) {
        ticker = len(y_path);
    }
    for i in range(ticker) {
        if x_path[i] == y_path[i] {
            result_path += x_path[i] + "\\";
        } else {
            break;
        }
    }
    if result_path == "" {
        return None;
    }
    return result_path;
}