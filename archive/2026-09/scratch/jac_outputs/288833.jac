"""Separate arguments passed to J2ObjC into source files and J2ObjC flags."""
def _ParseArgs(j2objc_args: list[str]) -> tuple[list[str], list[str]] {
    source_files = [];
    flags = [];
    is_next_flag_value = False;
    for j2objc_arg in j2objc_args {
        if j2objc_arg.startswith('-') {
            flags.append(j2objc_arg);
            is_next_flag_value = True;
        } elif is_next_flag_value {
            flags.append(j2objc_arg);
            is_next_flag_value = False;
        } else {
            source_files.append(j2objc_arg);
        }
    }
    return (source_files, flags);
}