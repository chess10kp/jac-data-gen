"""Map instrument codes to normalized STAC instrument names."""
def _as_stac_instruments(value: str) -> list[str] {
    return [i.strip("+-").lower() for i in value.split("_")];
}