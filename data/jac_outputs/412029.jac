""" Takes iterator of individual function maps and creates a global map
    keeping only unique names. We leave conflicting names out of CTU.
    A function map contains the id of a function (mangled name) and the
    originating source (the corresponding AST file) name."""
def create_global_ctu_function_map(func_map_lines: list[str]) -> list[tuple[str, str]] {
    mangled_to_asts = {};
    for line in func_map_lines {
        (mangled_name, ast_file) = line.strip().split(' ', 1);
        if mangled_name not in mangled_to_asts {
            mangled_to_asts[mangled_name] = {ast_file};
        } else {
            mangled_to_asts[mangled_name].add(ast_file);
        }
    }
    mangled_ast_pairs = [];
    for (mangled_name, ast_files) in mangled_to_asts.items() {
        if len(ast_files) == 1 {
            mangled_ast_pairs.append((mangled_name, ast_files.pop()));
        }
    }
    return mangled_ast_pairs;
}