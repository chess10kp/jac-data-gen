"""Extract the pacer case ID from the URL.

    In: https://ecf.almd.uscourts.gov/cgi-bin/DktRpt.pl?56120
    Out: 56120
    In: https://ecf.azb.uscourts.gov/cgi-bin/iquery.pl?625371913403797-L_9999_1-0-663150
    Out: 663150
    """
def get_pacer_case_id_from_nonce_url(url: Any) -> object {
    param = url.split("?")[1];
    if ("L" in param) {
        return param.rsplit("-", 1)[1];
    }
    return param;
}