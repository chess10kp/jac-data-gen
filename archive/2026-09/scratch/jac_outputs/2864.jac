""" remove app from installed_apps """
def remove_app(INSTALLED_APPS: tuple[str, ...], app: str) -> tuple[str, ...] {
    if app in INSTALLED_APPS {
        apps = list(INSTALLED_APPS);
        apps.remove(app);
        return tuple(apps);
    }
    return INSTALLED_APPS;
}