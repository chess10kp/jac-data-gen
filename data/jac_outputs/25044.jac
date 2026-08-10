"""
    :param _run_name:      [str], e.g. 'runA'
    :param _run_nr:        [int], e.g. 1
    :return: _run_name_nr: [str], e.g. 'runA-1'
    """
def get_run_name_nr(_run_name: Any, _run_nr: Any) -> object {
    return f"{_run_name}-{_run_nr}";
}