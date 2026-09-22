"""Print wrapped sequence."""
def wrap(seq: str, bases: int = 60) -> str {
    count = 0;
    ret = '';
    for i in seq {
        if count >= bases {
            ret = ret + '\n';
            count = 0;
        }
        ret = ret + i;
        count += 1;
    }
    return ret;
}