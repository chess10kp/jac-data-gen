"""Checks given arguments and passes correct ones to the compilation script."""
def analyze_arguments(arguments: list[str]) -> tuple[str | bool, str | bool, str, str | bool] {
    accepted_arg_prefix = [
        '--use_openbabel',
        '--use_cython',
        '--cython_compiler',
        '--overwrite'
    ];
    def _split(arg: str) -> tuple[str | None, str | None] {
        pos = arg.find('=');
        prefix = arg[:pos];
        suffix = arg[pos + 1:];
        return (None, None) if prefix not in accepted_arg_prefix else (prefix, suffix);
    }
    use_openbabel: str | bool = False;
    use_cython: str | bool = False;
    cython_compiler: str = 'msvc';
    overwrite: str | bool = False;
    if len(arguments) != 0 {
        for entry in arguments {
            data = _split(entry);
            if data[0] == '--use_cython' {
                use_cython = data[1] as str;
            } elif data[0] == '--cython_compiler' {
                cython_compiler = data[1] as str;
            } elif data[0] == '--use_openbabel' {
                use_openbabel = data[1] as str;
            } elif data[0] == '--overwrite' {
                overwrite = data[1] as str;
            }
        }
    }
    return (use_openbabel, use_cython, cython_compiler, overwrite);
}