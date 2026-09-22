"""Returns the currency symbol as specified by the exchange API docs.

NOTE: Some exchanges (kraken) use different naming conventions. (e.g. BTC->XBT)
"""
def map_currency(currency: str, currency_map: dict[str, str]) -> str {
    if currency not in currency_map {
        return currency;
    }
    return currency_map[currency];
}