"""Parse an attribute line.

    Arguments:
    line -- a single line from the tlpdb

    Returns:
    A dictionary of attributes

    Example input lines:

        arch=x86_64-darwin size=1
        details="Package introduction" language="de"
        RELOC/doc/platex/pxbase/README details="Readme" language="ja"

    """
def _attributes_from_line(line: Any) -> object {
    key = None;
    value = None;
    chars = [];
    quote_count = 0;
    attrs = {};
    for c in line {
        if (c == "=") {
            if (key == None) {
                assert (quote_count == 0) , ("possibly quoted key in line %s" % line);
                key = "".join(chars);
                chars = [];
            } else {
                chars.append(c);
            }
        } elif (c == "\"") {
            quote_count += 1;
        } elif (c == " ") {
            if ((quote_count % 2) == 0) {
                assert (key != None) , ("no key found for %s" % line);
                assert (key not in attrs) , ("key already assigned for line %s" % line);
                attrs[key] = "".join(chars);
                chars = [];
                key = None;
                quote_count = 0;
            } else {
                chars.append(c);
            }
        } else {
            chars.append(c);
        }
    }
    assert (key != None) , ("no key found for %s" % line);
    assert len(chars) , ("no values found for line %s" % line);
    attrs[key] = "".join(chars);
    return attrs;
}