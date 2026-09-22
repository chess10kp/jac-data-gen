"""
Local helper function that takes a pettingzoo config path and returns it in
the service_class/service_name format expected in this module
"""
def _config_path_to_class_and_name(path: str) -> tuple[str, str] {
    path = path.split(".")[0];
    parts = path.split("/");
    if len(parts) >= 2 {
        return (parts[-2], parts[-1]);
    }
    raise Exception("Config path cannot be parsed: %s" % path);
}