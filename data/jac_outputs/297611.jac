"""Get the project-relative path to some Python class, method, or function.

    Args:
        namespace (str):
            The importable Python location of some class, method, or function.
            Example: "foo.bar.ClassName.get_method_data".
        directive (str):
            The Python type that `namespace` is. Example: "py:method".

    Raises:
        EnvironmentError:
            If `directive` and `namespace` were both found properly but,
            for some reason, the top-level website / file path for the
            Sphinx project stored by intersphinx could not be found.

    Returns:
        tuple[str, str]:
            The exact path, relative to a Sphinx project's root
            directory, where this module is tagged, followed by a tag
            like "foo" which will be later used to get a permalink to
            some header in the HTML file.

    """
def _get_module_tag(namespace: str, directive: str) -> tuple[str, str] {
    tokens = namespace.split(".");
    if directive in {"py:method"} {
        base = "/".join(tokens[:-2]);
        return ("_modules/{base}.html".format(base=base), ".".join(tokens[-2:]));
    }
    base = "/".join(tokens[:-1]);
    return ("_modules/{base}.html".format(base=base), tokens[-1]);
}