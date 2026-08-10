"""Appends dir2 to dir1. It is possible that either/both dir1 or/and dir2 is/are None"""
def concatenate_dirs(dir1: str | None, dir2: str | None) -> str {
    result_dir = dir1 if dir1 is not None and len(dir1) > 0 else '';
    if dir2 is not None and len(dir2) > 0 {
        if len(result_dir) == 0 {
            result_dir = dir2;
        } else {
            result_dir += '/' + dir2;
        }
    }
    return result_dir;
}