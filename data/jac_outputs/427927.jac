"""Returns True if ANY of the plugins require a page reload when action is taking place."""
def requires_reload(action: str, plugins: list) -> bool {
    return `any(p.get_plugin_class_instance().requires_reload(action) for p in plugins);
}