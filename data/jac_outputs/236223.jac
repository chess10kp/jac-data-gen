"""Checks to see if a help message needs to be printed for an addon.

Not all addons check for help flags themselves. Until they do, intercept
calls to print help text and print out a generic message to that effect."""
def check_help_flag(addons: list[str]) -> bool {
    addon = addons[0];
    if any(help_arg in addons for help_arg in ("-h", "--help")) {
        print("Addon %s does not yet have a help message." % addon);
        print("For more information about it, visit https://microk8s.io/docs/addons");
        return True;
    }
    return False;
}