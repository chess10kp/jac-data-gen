"""
    This Function takes in...

    :param wfrun: cachedir
    :return:
    """
def _nipype_logging_config(cachedir: Any) -> object {
    return {
        "workflow_level": "INFO",
        "filemanip_level": "INFO",
        "interface_level": "INFO",
        "log_directory": cachedir
    };
}