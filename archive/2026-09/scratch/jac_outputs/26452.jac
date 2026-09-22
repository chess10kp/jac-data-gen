"""Helper to create a logfile path incorporating the thread ID in the filename before the file type suffix."""
def build_logfile_path(
    logname: str, logType: str, threadId: int, log_num: int = 1
) -> str {
    type_start = logname.rfind(".txt");
    return f"{logname[:type_start]}.{logType}.{threadId!s}.{log_num!s}{logname[type_start:]}";
}