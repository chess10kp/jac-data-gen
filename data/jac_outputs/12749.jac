"""
    Make a subject string

    :param common_name: Common name used in certificate
    :param encrypted: Add the encrypted flag to the organisation
    :return: A subject string
    """
def make_subj(common_name: Any, encrypted: Any = False) -> object {
    return "/C=FR/ST=Auvergne-Rhone-Alpes/L=Grenoble/O=iPOPO Tests ({0})"
    "/CN={1}".format(
        "encrypted" if encrypted else "plain", common_name
    );
}