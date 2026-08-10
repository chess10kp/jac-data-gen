"""Render the application label."""
def render_app_label(context: object, app: dict[str, str] | str, fallback: str = "") -> str {
    try {
        text = app['app_label'];
    } except KeyError {
        text = fallback;
    } except TypeError {
        text = app as str;
    }
    return text;
}