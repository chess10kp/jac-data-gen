"""
    Given an item title, returns the appropriate QuickBooks class and account

    Parameter: item_title
    Returns: item_class, item_account

    Note that this is only guaranteed to work for Ticketleap sales, not
    PayPal invoices.

    """
def qb_account(item_title: str) -> tuple[str, str] {
    if 'Northern' in item_title or 'NLC' in item_title {
        item_class = 'NLC';
    } else {
        item_class = 'CCC';
    }
    if 'Competitor' in item_title {
        item_account = 'Competition Income:Competitors:' 'Amateur Registration Fees';
    } else {
        item_account = 'Competition Income:Sales:Tickets:Advance Tickets';
    }
    return (item_class, item_account);
}