"""Helper function to create offer name strings."""
def _offer_label_composition(sku: str, offer_multiple: int) -> str {
    return "".join([sku, str(offer_multiple), "_offer"]);
}