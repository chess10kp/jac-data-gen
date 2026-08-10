"""Convert a plugin package name into its class or config name."""
def sanitize_plugin_class_name(plugin_name: str | None, config: bool = False) -> str {
    if plugin_name is None {
        return "";
    }
    parts = plugin_name.split("_");
    sanitized = [part.capitalize() for part in parts];
    sanitized.append("Plugin" if not config else "Config");
    return "".join(sanitized);
}