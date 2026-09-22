"""Is a transaction a coinbase transaction?"""
def tx_is_coinbase(tx: dict[str, list[dict[str, str]]]) -> bool {
    for inp in tx['vin'] {
        if 'coinbase' in inp.keys() {
            return True;
        }
    }
    return False;
}