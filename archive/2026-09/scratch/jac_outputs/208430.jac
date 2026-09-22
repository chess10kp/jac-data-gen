"""Looks up instrument token for a given script from instrument dump"""
def instrumentLookup(instrument_df: Any, symbol: Any) -> object {
    try {
        return instrument_df[
            (instrument_df.tradingsymbol == symbol)
        ].instrument_token.values[0];
    } except Exception as e {
        return -1;
    }
}