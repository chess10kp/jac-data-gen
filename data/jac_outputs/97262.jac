"""Converts defaults to specific items for this view."""
def getItemsFromDefaults(defaults: list[tuple[str, str, object]], params: dict[str, str]) -> list[tuple[str, str, object]] {
    return [(url % params['url_name'].lower(), menu_text % params, access_type) for (url, menu_text, access_type) in defaults];
}