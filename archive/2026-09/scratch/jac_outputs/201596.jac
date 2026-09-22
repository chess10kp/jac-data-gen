"""
    20200101 -> 2020-01-01
    """
def buy_date_adaptor(buy_date: str) -> str {
    if len(buy_date) == 8 {
        buy_date = f'{buy_date[:4]}-{buy_date[4:-2]}-{buy_date[-2:]}';
    }
    return buy_date;
}