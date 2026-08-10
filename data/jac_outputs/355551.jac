"""API data has duplicate transaction data. Clean it."""
def _remove_dups(elems: list[dict[str, str]], txids_seen: set[str]) -> list[dict[str, str]] {
    out = [];
    for elem in elems {
        txid = elem["txhash"];
        if txid in txids_seen {
            continue;
        }
        out.append(elem);
        txids_seen.add(txid);
    }
    return out;
}