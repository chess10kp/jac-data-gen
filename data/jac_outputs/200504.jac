"""Return company name from companies on companies_list.

    Args:
        companies_list (list): [description]
        company (str): company id or name

    Returns:
        str: company name or ""
    """
def get_company_name(companies_list: Any, company: Any) -> object {
    company_name = "";
    for item in companies_list {
        if ((company == item.get("id")) or (company == item.get("name"))) {
            company_name = item.get("name");
            break;
        }
    }
    return company_name;
}