""" for mac retina displays """
def scale_dimensions(dic: Any, size: Any = 2) -> object {
    for x in dic {
        dic[x] = int((dic[x] * size));
    }
    return dic;
}