"""Creates a dict to use with send_list."""
def list_element(
    title: str,
    subtitle: str | None = None,
    image_url: str | None = None,
    buttons: list[dict[str, str]] | None = None,
    default_action: dict[str, str] | None = None
) -> dict[str, str | list[dict[str, str]] | dict[str, str] | None] {
    payload: dict[str, str | list[dict[str, str]] | dict[str, str] | None] = {
        'title': title,
        'image_url': image_url,
        'subtitle': subtitle,
        'default_action': default_action,
        'buttons': buttons
    };
    if not subtitle {
        payload.pop('subtitle');
    }
    if not image_url {
        payload.pop('image_url');
    }
    if not buttons {
        payload.pop('buttons');
    }
    if not default_action {
        payload.pop('default_action');
    }
    return payload;
}