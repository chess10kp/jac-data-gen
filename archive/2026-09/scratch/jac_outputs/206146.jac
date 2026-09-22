"""
    Checks XML for JavaScript. See "security" in :doc:`customization <../../customization>` for
    additional information.

    :param data: Contents to be monitored for JavaScript injection.
    :type data: str, bytes
    :return: ``True`` if **data** contains JavaScript tag(s), otherwise ``False``.
    :rtype: bool
    """
def xml_has_javascript(data: Any) -> object {
    import from re { search, IGNORECASE, MULTILINE }
    data = str(data, encoding='UTF-8');
    print(data);
    pattern = r'(<\s*\bscript\b.*>.*)|(.*\bif\b\s*\(.?={2,3}.*\))|(.*\bfor\b\s*\(.*\))';
    found = search(pattern=pattern, string=data, flags=(IGNORECASE | MULTILINE));
    if (found is not None) {
        return True;
    }
    import from xml.etree.ElementTree { fromstring }
    parsed_xml = (
        (attribute, value) for elm in fromstring(data).iter()
        for (attribute, value) in elm.attrib.items()
    );
    for (key, val) in parsed_xml {
        if (('"' in val) or ("'" in val)) {
            return True;
        }
    }
    return False;
}