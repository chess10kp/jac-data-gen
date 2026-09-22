"""Divides file path to bucket name and file name"""
def parse_file_to_bucket_and_filename(file_path: str) -> tuple[str, str] {
    path_parts = file_path.split("//");
    if len(path_parts) >= 2 {
        main_part = path_parts[1];
        if "/" in main_part {
            divide_index = main_part.index("/");
            bucket_name = main_part[:divide_index];
            file_name = main_part[divide_index + 1:];
            return (bucket_name, file_name);
        }
    }
    return ("", "");
}