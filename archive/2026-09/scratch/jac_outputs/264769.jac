"""Splits a string into the name and version number.

    Name and version must be seperated with a hyphen ('-')
    or double hyphen ('--').
    'TextWrangler-2.3b1' becomes ('TextWrangler', '2.3b1')
    'AdobePhotoshopCS3--11.2.1' becomes ('AdobePhotoshopCS3', '11.2.1')
    'MicrosoftOffice2008-12.2.1' becomes ('MicrosoftOffice2008', '12.2.1')
    """
def nameAndVersion(aString: str) -> tuple[str, str] {
    for delim in ('--', '-') {
        if aString.count(delim) > 0 {
            chunks = aString.split(delim);
            vers = chunks.pop();
            name = delim.join(chunks);
            if vers[0] in '0123456789' {
                return (name, vers);
            }
        }
    }
    return (aString, '');
}