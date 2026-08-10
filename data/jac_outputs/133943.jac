def _specs(
    iport: dict[str, str],
    entity: dict[str, str],
    features: list[str]
) -> dict[str, dict[str, str] | list[str]] {
    return {"import": iport, "features": features, "entity": entity};
}