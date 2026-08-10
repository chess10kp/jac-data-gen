"""Replaces '/' with '&'."""
def station_name_udf(name: str | None) -> str | None {
    return name.replace("/", "&") if name else None;
}