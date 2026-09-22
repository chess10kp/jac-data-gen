"""Derive address encoding (base58 or bech32) from transaction witness type."""
def get_encoding_from_witness(witness_type: str | None = None) -> str {
    if witness_type == 'segwit' {
        return 'bech32';
    } elif witness_type in (None, 'legacy', 'p2sh-segwit') {
        return 'base58';
    } else {
        raise ValueError("Unknown witness type %s" % witness_type);
    }
}