""" Return a list of module names from a filename list. """
def get_python_module_names(file_list: Any, file_suffix: Any = '.py') -> object {
    module_names = [
        m[:m.rfind(file_suffix)]
        for m in file_list
        if m.endswith(file_suffix)
    ];
    return module_names;
}