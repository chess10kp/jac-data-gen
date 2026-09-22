"""
    Computes the main income statement items.

    Parameters
    ----------
    revenue : int or float
        Revenue for the period
    cogs : int or float
        Cost of goods sold
    sg_a : int or float
        Selling, general and administrative cost
    d_and_a : int or float
        Depreciation and amortizatin
    int_exp : int or float
        Interest expense
    tax : int or float
        Income tax
    other_revenue : int or float
        Optional, other revenue

    Returns
    -------
    out : dict
        Returns a dictionary with income statement items; total revenue, gross profit, ebitda, ebit, ebt, net income
    """
def inc_statement(
    revenue: Any,
    cogs: Any,
    sg_a: Any,
    d_and_a: Any,
    int_exp: Any,
    tax: Any,
    other_revenue: Any = 0
) -> object {
    total_revenue = revenue + other_revenue;
    gross_profit = total_revenue - cogs;
    ebitda = gross_profit - sg_a;
    ebit = ebitda - d_and_a;
    ebt = ebit - int_exp;
    net_income = ebt - tax;
    income_dict = {
        "total_revenue": total_revenue,
        "gross_profit": gross_profit,
        "ebitda": ebitda,
        "ebit": ebit,
        "ebt": ebt,
        "net_income": net_income
    };
    return income_dict;
}