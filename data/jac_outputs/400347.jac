"""
    :param state_code: 3 digit alphanumeric code
    :param ac_code: numeric
    :return:
    """
def get_url(state_code: Any, ac_code: Any) -> object {
    url = f"http://results.eci.gov.in/pc/en/constituencywise/Constituencywise{state_code}{ac_code}.htm?ac={ac_code}";
    return url;
}