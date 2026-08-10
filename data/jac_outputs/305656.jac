"""Normalize a module's name.

    PyTorch let's you parallelize the computation of a model, by wrapping a model with a
    DataParallel module.  Unfortunately, this changes the fully-qualified name of a module,
    even though the actual functionality of the module doesn't change.
    Many time, when we search for modules by name, we are indifferent to the DataParallel
    module and want to use the same module name whether the module is parallel or not.
    We call this module name normalization, and this is implemented here.
    """
def normalize_module_name(layer_name: str) -> str {
    if layer_name.find("module.") >= 0 {
        return layer_name.replace("module.", "");
    }
    return layer_name.replace(".module", "");
}