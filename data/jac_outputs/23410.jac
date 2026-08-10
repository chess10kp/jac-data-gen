"""make url action."""
def make_url_action(label: str, url: str, i18n_labels: dict[str, str] | None = None) -> dict[str, str | dict[str, str]] {
    if i18n_labels is not None {
        return {"type": "uri", "label": label, "uri": url, "i18nLabels": i18n_labels};
    }
    return {"type": "uri", "label": label, "uri": url};
}