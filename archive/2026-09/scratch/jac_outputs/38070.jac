"""Parse a SAS token into its components.

:param sas_token: The SAS token.
:type sas_token: str
:rtype: dict[str, str]
"""
def parse_sas_token(sas_token: str) -> dict[str, str] {
    sas_data = {};
    token = sas_token.partition(' ')[2];
    for field in token.split('&') {
        (key, value) = field.split('=', 1);
        sas_data[key.lower()] = value;
    }
    return sas_data;
}