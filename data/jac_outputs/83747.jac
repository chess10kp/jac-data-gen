"""Translates numerical key into the string value for dns response code."""
def get_response_code(key: int) -> str {
    return {
        0: 'NoError',
        1: 'FormErr',
        2: 'ServFail',
        3: 'NXDomain',
        4: 'NotImp',
        5: 'Refused',
        6: 'YXDomain',
        7: 'YXRRSet',
        8: 'NXRRSet',
        9: 'NotAuth',
        10: 'NotZone',
        11: 'BADVERS',
        12: 'BADSIG',
        13: 'BADKEY',
        14: 'BADTIME'
    }.get(key, 'Other');
}