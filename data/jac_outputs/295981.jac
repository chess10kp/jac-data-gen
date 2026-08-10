"""Split short options list used by getopt. Returns a set of the options."""
def _split_short_opt_list(short_opt_list: str) -> set[str] {
    res = set();
    tmp = short_opt_list[:];
    while tmp {
        if len(tmp) > 1 and tmp[1] is ':' {
            res.add(tmp[0:2]);
            tmp = tmp[2:];
        } else {
            res.add(tmp[0]);
            tmp = tmp[1:];
        }
    }
    return res;
}