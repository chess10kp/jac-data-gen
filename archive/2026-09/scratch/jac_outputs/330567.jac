"""
    Function decides if current file a script according to its root and full name
    :param root: path to the file
    :param full_file_name: name of file with extension (if present)
    :return: boolean value, if file is a script
    """
def is_script(`root: Any, full_file_name: Any) -> object {
    is_script_result = False;
    if ('.' in full_file_name) {
        (file_name, extension) = full_file_name.rsplit('.', 1);
        if (
            (extension in ["xlsx", "xls"]) and file_name.startswith("RobotScenario_")
        ) {
            is_script_result = True;
        }
    }
    return is_script_result;
}