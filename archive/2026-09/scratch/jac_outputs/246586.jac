"""
Store data in file named `file_name`
"""
def store_on_fs(data: str | int | float | bool | list | dict, file_name: str) -> bool | None {
    if data {
        with open(file_name, "w") as f {
            f.write(str(data));
        }
        return True;
    }
}