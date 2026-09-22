"""Reads line?"""
def read_error_line(l: str) -> tuple[str, float, float] {
    print('_read_error_line -> line>', l);
    (name, values) = l.split('   ', 1);
    print('_read_error_line -> name>', name);
    print('_read_error_line -> values>', values);
    name = name.strip(': ').strip();
    values = values.strip(': ').strip();
    (v, error) = values.split(" +/- ");
    return (name, float(v), float(error));
}