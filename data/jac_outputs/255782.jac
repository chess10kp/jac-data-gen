"""by looking at arguments we try to generate a proper identifier
    >>> get_process_identifier(['python', 'echo.py', '1'])
    'python_echo.py_1'
"""
def get_process_identifier(args: list[str]) -> str {
    return '_'.join(args);
}