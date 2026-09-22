"""sorting function, by just comparing elements to elements, requires implementation of __gt__. Probably not the fastest version (n**2)"""
def compsort(q: list[int]) -> list[int] {
    ret = [];
    for (j, qq) in enumerate(q) {
        for (i, k) in enumerate(ret) {
            if k > qq {
                ret.insert(i, qq);
                break;
            }
        }
        if len(ret) <= j {
            ret.append(qq);
        }
    }
    return ret;
}