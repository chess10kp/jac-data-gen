""" scalar version of numpy.where """
def where_math(condition: bool | int | float | str, x: bool | int | float | str, y: bool | int | float | str) -> bool | int | float | str {
    return x if condition else y;
}