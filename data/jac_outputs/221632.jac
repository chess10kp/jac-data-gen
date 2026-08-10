""" swap arr[axis] and arr[-1] """
def swap(arr: Any, axis: Any) -> object {
    return (arr[:axis] + [arr[-1]] + arr[(axis + 1):-1] + [arr[axis]]);
}