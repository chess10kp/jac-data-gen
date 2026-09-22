"""Determine whether we are doing a sector-based forecast."""
def _has_sectors(tax_name: str, ignore_sectors: bool) -> bool {
    return tax_name in ["birt", "sales", "wage", "rtt"] and not ignore_sectors;
}