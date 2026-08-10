"""Compares TX and RX bases and return the selected bits."""
def compare_bases_and_generate_key(
    tx_bases: str, rx_bases: str, measure: str
) -> tuple[str | None, str | None] {
    if not len(tx_bases) == len(rx_bases) == len(measure) {
        return (
            None,
            "tx_bases(%d), rx_bases(%d) and measure(%d) must have the same length."
            % (len(tx_bases), len(rx_bases), len(measure))
        );
    }
    ret = ''.join(
        bit for (bit, tx_base, rx_base) in zip(measure, tx_bases, rx_bases)
        if tx_base == rx_base
    );
    return (ret, None);
}