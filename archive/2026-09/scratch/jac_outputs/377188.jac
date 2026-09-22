"""Given source lines for a method or function, get the function block lines."""
def get_func_definition(sourcelines: list[str]) -> tuple[list[str], list[str]] {
    count = 1;
    for line in sourcelines {
        if line.rstrip().endswith(':') {
            break;
        }
        count += 1;
    }
    (sourcelines[:count], sourcelines[count:])
}