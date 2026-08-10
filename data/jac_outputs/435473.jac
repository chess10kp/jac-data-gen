"""Convert a compartment ID in ModelSEED source format to another format.

No conversion is done for unknown format types."""
def convert_compartment_id(modelseed_id: str, format_type: str) -> str {
    if format_type in ('modelseed', 'bigg') {
        return modelseed_id[0];
    }
    return modelseed_id;
}