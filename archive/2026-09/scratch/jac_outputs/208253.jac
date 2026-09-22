import from xml.etree.ElementTree { Element }

"""Check res is not None and res.attrib['stat'] == "ok" for XML object."""
def is_good(res: Element | str | None) -> bool {
    return False
        if res is None
        else not res == "" and (res as Element).attrib['stat'] == "ok";
}