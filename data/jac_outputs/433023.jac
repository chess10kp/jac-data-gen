"""Format constructor arguments; returns a list"""
def format_ctor_arguments(arguments: list[str | int], parent: str, id: str | int, size: str) -> list[str | int] {
    v_size = size.split(',');
    for (i, arg) in enumerate(arguments) {
        if arg == '$parent' {
            arguments[i] = parent;
        } elif arg == '$id' {
            arguments[i] = id;
        } elif arg == '$width' {
            arguments[i] = v_size[0];
        } elif arg == '$height' {
            arguments[i] = v_size[1];
        }
    }
    return arguments;
}