glob XML_CHAR_MIN = 0x20;
glob XML_CHAR_MAX = 0xD7FF;
glob XML_CHAR_EXT_MIN = 0xE000;
glob XML_CHAR_EXT_MAX = 0xFFFD;
glob XML_CHAR_SUP_MIN = 0x10000;
glob XML_CHAR_SUP_MAX = 0x10FFFF;

"""Check if a character is valid in xml."""
def valid_xml_char_ordinal(c: str) -> bool {
    codepoint = ord(c);
    return (
        XML_CHAR_MIN <= codepoint <= XML_CHAR_MAX
        or codepoint in (9, 10, 13)
        or XML_CHAR_EXT_MIN <= codepoint <= XML_CHAR_EXT_MAX
        or XML_CHAR_SUP_MIN <= codepoint <= XML_CHAR_SUP_MAX
    );
}