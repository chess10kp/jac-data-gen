"""Build new dependencies dict skipping the executed script."""
def _remove_script_from_dependencies(
    executed_script: str, script_dependencies: dict[str, list[str]]
) -> dict[str, list[str]] {
    new_dependencies = dict();
    for (script_path, dependencies) in script_dependencies.items() {
        if script_path != executed_script {
            new_dependencies[script_path] = [
                d for d in dependencies if d != executed_script
            ];
        }
    }
    return new_dependencies;
}