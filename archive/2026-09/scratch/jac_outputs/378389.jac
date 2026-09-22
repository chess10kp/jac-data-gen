"""This function checks if the user input of Cryptocurrency type
or Fiat Money type are truly the latter.
Returns 1 if found an error in the input, else returns 0."""
def validity_of_currencytype(ctype: Any, ftype: Any) -> object {
    available_cryptocurrencies = [
        'ADA',
        'BTC',
        'BSV',
        'ETH',
        'ETC',
        'BCH',
        'LINK',
        'LTC',
        'DOGE',
        'ZEC',
        'SHIB',
        'ZRX',
        'MKR',
        'MATIC',
        'USDC',
        'XRP',
        'DOT',
        'XLM'
    ];
    if (ctype not in available_cryptocurrencies) {
        return (1, f"\n{ctype} is not a Cryptocurrency. Try Again!\n");
    } elif (ftype in available_cryptocurrencies) {
        return (1, f"\n{ftype} is not a Fiat Money. Try Again!\n");
    } else {
        return (0, "\nAll Good!");
    }
}