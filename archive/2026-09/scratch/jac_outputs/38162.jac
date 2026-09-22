"""Provide a library_path property to the template if it exists"""
def library_path(hsm: object) -> str {
    try {
        relation = getattr(hsm, "relation");
        plugin_data = getattr(relation, "plugin_data");
        return plugin_data["library_path"];
    } except Exception {
        return "";
    }
}