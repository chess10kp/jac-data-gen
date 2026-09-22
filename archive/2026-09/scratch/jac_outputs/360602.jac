"""
Only add when mapall option is used and
"-q" and "--reads-queue-size" is not already used.
"""
def _add_read_queue_size(input_cmd: str, queue_size: int = 50000) -> str {
    if "mapall" not in input_cmd {
        return input_cmd;
    }
    if "-q" in input_cmd or "--reads-queue-size" in input_cmd {
        return input_cmd;
    }
    return input_cmd + ("-q %d" % queue_size);
}