import from xml.etree.ElementTree { Element }

""" Helping function which returns None or the href attribute.

    Since some xml documents use https for the w3.org reference,
    it is nicer to encapsulate the logic inside this separate function.

    Args:
        xml_elem: The xml element
    Returns:
         None | the attribute
    """
def get_href_attribute(xml_elem: Element | None) -> str | None {
    xlink = None;
    if xml_elem is not None {
        for tag in [
            "{http://www.w3.org/1999/xlink}href",
            "{https://www.w3.org/1999/xlink}href"
        ] {
            xlink = xml_elem.get(tag);
            if xlink is not None {
                break;
            }
        }
    }
    return xlink;
}