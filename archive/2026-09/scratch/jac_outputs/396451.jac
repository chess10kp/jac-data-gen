"""
format 1-2-3... to 00001-00002-00003...
src should be convertable to int
"""
def sort_format(src: str) -> str {
    src_list = src.split('-');
    res_list = [];
    for elm in src_list {
        try {
            res_list.append('%05d' % int(elm));
        } except Exception {
            res_list.append(elm);
        }
    }
    return '-'.join(res_list);
}