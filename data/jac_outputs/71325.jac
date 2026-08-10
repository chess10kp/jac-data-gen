""" Find oldest time object in "bak_dir_time_objs" structure.
        recurse_val = 0 -> start with top entry "year", default
    """
def find_old_backup(bak_dir_time_objs: list[list[int]], recurse_val: int = 0) -> list[int] {
    tmp = [timeobj[recurse_val] for timeobj in bak_dir_time_objs];
    min_val = min(tmp);
    new_timeobj = [timeobj for timeobj in bak_dir_time_objs if timeobj[recurse_val] == min_val];
    if len(new_timeobj) > 1 {
        return find_old_backup(new_timeobj, recurse_val + 1);
    }
    return new_timeobj[0];
}