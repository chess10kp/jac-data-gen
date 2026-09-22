"""Construct map from function names to GL versions which define them."""
def GetFunctionToGLVersionsMap(gl_versions: dict[str, list[str]]) -> dict[str, set[str]] {
    function_to_gl_versions = {};
    for (gl_version, functions) in gl_versions.items() {
        for function in functions {
            if function not in function_to_gl_versions {
                function_to_gl_versions[function] = set([]);
            }
            function_to_gl_versions[function].add(gl_version);
        }
    }
    return function_to_gl_versions;
}