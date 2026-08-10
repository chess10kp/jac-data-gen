"""Convert File,Directory or [File,Directory] into string or a list of string"""
def convert_to_string(value: dict[str, str] | list[dict[str, str] | str | int | float | bool] | tuple[dict[str, str] | str | int | float | bool, ...] | str | int | float | bool) -> dict[str, str] | list[dict[str, str] | str | int | float | bool] | tuple[dict[str, str] | str | int | float | bool, ...] | str | int | float | bool {
    if type(value) is dict and (value as dict[str, str]).get("class") in ["File", "Directory"] {
        return (value as dict[str, str])["path"];
    } elif type(value) is list or type(value) is tuple {
        converted_list = [];
        for item in value {
            if type(item) is dict and (item as dict[str, str]).get("class") in ["File", "Directory"] {
                item_dict = item as dict[str, str];
                path = item_dict["path"];
                converted_list.append(path);
            } else {
                converted_list.append(item);
            }
        }
        return converted_list;
    } else {
        return value;
    }
}