"""Android L public notification payload builder."""
def public_notification(
    title: str | None = None,
    alert: str | None = None,
    summary: str | None = None
) -> dict[str, str] {
    payload = {"title": title, "alert": alert, "summary": summary};
    return {
        key: val
        for (key, val) in iter(payload.items())
        if val is not None
    };
}