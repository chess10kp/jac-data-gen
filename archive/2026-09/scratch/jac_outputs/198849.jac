"""Get a directory path from module, relative to root of repository.

E.g. zenml.core.step will return zenml/core/step.
"""
def get_relative_path_from_module_source(module_source: str) -> str {
    return module_source.replace('.', '/');
}