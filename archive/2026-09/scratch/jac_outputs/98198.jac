"""Parse the module name from a main_is attribute."""
def _get_main_is_module(main_is: str) -> str {
    components = main_is.split(".");
    if components and components[-1] and components[-1][0:1].islower() {
        return ".".join(components[:-1]);
    } else {
        return main_is;
    }
}