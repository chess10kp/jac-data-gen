"""
Method to obtain module and class_name from a module path.

Returns tuple containing class_name and module.
"""
def process_path(module_path: str) -> tuple[str, str] {
    if module_path == 'numpy.ndarray' {
        return ('StorageNumpy', 'hecuba.hnumpy');
    }
    if module_path == 'StorageDict' {
        return ('StorageDict', 'hecuba.hdict');
    }
    last = 0;
    for (idx, ch) in enumerate(module_path) {
        if ch == '.' and idx > last {
            last = idx;
        }
    }
    module = module_path[:last];
    class_name = module_path[(last + 1):];
    return (class_name, module);
}