"""Determine action to which string belong."""
def _inside_this_control_function(cf: dict[str, str | int], file: str, line: int) -> bool {
    cf['file'] == file and cf['begin'] <= line <= cf['end']
}